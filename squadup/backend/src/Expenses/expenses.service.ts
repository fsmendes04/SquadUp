import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { FilterExpensesDto } from './dto/filter-expenses.dto';
import { Expense, ExpenseWithParticipants, ExpenseParticipant } from './models/expense.model';

@Injectable()
export class ExpensesService {
  constructor(private readonly supabaseService: SupabaseService) { }

  async createExpense(createExpenseDto: CreateExpenseDto, userId: string): Promise<ExpenseWithParticipants> {
    const { group_id, payer_id, amount, description, category, expense_date, participant_ids } = createExpenseDto;

    await this.validateGroupMembership(group_id, userId);
    await this.validateGroupMembership(group_id, payer_id);
    for (const participantId of participant_ids) {
      await this.validateGroupMembership(group_id, participantId);
    }

    const amountPerParticipant = amount / participant_ids.length;

    const { data: expense, error: expenseError } = await this.supabaseService.client
      .from('expenses')
      .insert({
        group_id,
        payer_id,
        amount,
        description,
        category,
        expense_date,
      })
      .select()
      .single();

    if (expenseError) {
      throw new BadRequestException(`Erro ao criar despesa: ${expenseError.message}`);
    }

    // Adicionar participantes
    const participantsData = participant_ids.map(participantId => ({
      expense_id: expense.id,
      user_id: participantId,
      amount_owed: amountPerParticipant,
    }));

    const { error: participantsError } = await this.supabaseService.client
      .from('expense_participants')
      .insert(participantsData);

    if (participantsError) {
      // Se falhar ao adicionar participantes, deletar a despesa criada
      await this.supabaseService.client
        .from('expenses')
        .delete()
        .eq('id', expense.id);

      throw new BadRequestException(`Erro ao adicionar participantes: ${participantsError.message}`);
    }

    return this.getExpenseById(expense.id, userId);
  }

  async updateExpense(expenseId: string, updateExpenseDto: UpdateExpenseDto, userId: string): Promise<ExpenseWithParticipants> {
    // Verificar se a despesa existe e se o usuário tem permissão
    const expense = await this.getExpenseById(expenseId, userId);

    // Verificar se o usuário é membro do grupo
    await this.validateGroupMembership(expense.group_id, userId);

    const updateData: any = {};

    if (updateExpenseDto.amount !== undefined) {
      updateData.amount = updateExpenseDto.amount;
    }
    if (updateExpenseDto.description !== undefined) {
      updateData.description = updateExpenseDto.description;
    }
    if (updateExpenseDto.category !== undefined) {
      updateData.category = updateExpenseDto.category;
    }
    if (updateExpenseDto.expense_date !== undefined) {
      updateData.expense_date = updateExpenseDto.expense_date;
    }

    // Atualizar a despesa
    const { error: expenseError } = await this.supabaseService.client
      .from('expenses')
      .update(updateData)
      .eq('id', expenseId)
      .is('deleted_at', null);

    if (expenseError) {
      throw new BadRequestException(`Erro ao atualizar despesa: ${expenseError.message}`);
    }

    // Se houver novos participantes, atualizar
    if (updateExpenseDto.participant_ids) {
      // Verificar se todos os participantes são membros do grupo
      for (const participantId of updateExpenseDto.participant_ids) {
        await this.validateGroupMembership(expense.group_id, participantId);
      }

      // Remover participantes existentes
      await this.supabaseService.client
        .from('expense_participants')
        .delete()
        .eq('expense_id', expenseId);

      // Calcular novo valor por participante
      const newAmount = updateExpenseDto.amount || expense.amount;
      const amountPerParticipant = newAmount / updateExpenseDto.participant_ids.length;

      // Adicionar novos participantes
      const participantsData = updateExpenseDto.participant_ids.map(participantId => ({
        expense_id: expenseId,
        user_id: participantId,
        amount_owed: amountPerParticipant,
      }));

      const { error: participantsError } = await this.supabaseService.client
        .from('expense_participants')
        .insert(participantsData);

      if (participantsError) {
        throw new BadRequestException(`Erro ao atualizar participantes: ${participantsError.message}`);
      }
    } else if (updateExpenseDto.amount) {
      // Se apenas o valor foi alterado, atualizar os valores dos participantes existentes
      const { data: participants } = await this.supabaseService.client
        .from('expense_participants')
        .select('*')
        .eq('expense_id', expenseId);

      if (participants && participants.length > 0) {
        const amountPerParticipant = updateExpenseDto.amount / participants.length;

        const { error: updateParticipantsError } = await this.supabaseService.client
          .from('expense_participants')
          .update({ amount_owed: amountPerParticipant })
          .eq('expense_id', expenseId);

        if (updateParticipantsError) {
          throw new BadRequestException(`Erro ao atualizar valores dos participantes: ${updateParticipantsError.message}`);
        }
      }
    }

    return this.getExpenseById(expenseId, userId);
  }

  async deleteExpense(expenseId: string, userId: string): Promise<void> {
    // Verificar se a despesa existe e se o usuário tem permissão
    const expense = await this.getExpenseById(expenseId, userId);

    // Verificar se o usuário é membro do grupo
    await this.validateGroupMembership(expense.group_id, userId);

    // Soft delete
    const { error } = await this.supabaseService.client
      .from('expenses')
      .update({ deleted_at: new Date().toISOString() })
      .eq('id', expenseId)
      .is('deleted_at', null);

    if (error) {
      throw new BadRequestException(`Erro ao deletar despesa: ${error.message}`);
    }
  }

  async getExpenseById(expenseId: string, userId: string): Promise<ExpenseWithParticipants> {
    const { data: expense, error } = await this.supabaseService.client
      .from('expenses')
      .select(`
        *,
        participants:expense_participants(*)
      `)
      .eq('id', expenseId)
      .is('deleted_at', null)
      .single();
    if (error || !expense) {
      throw new NotFoundException('Despesa não encontrada');
    }
    // Verificar se o usuário é membro do grupo
    await this.validateGroupMembership(expense.group_id, userId);
    return expense;
  }

  async getExpensesByGroup(groupId: string, userId: string, filters?: FilterExpensesDto): Promise<ExpenseWithParticipants[]> {
    // Verificar se o usuário é membro do grupo
    await this.validateGroupMembership(groupId, userId);

    let query = this.supabaseService.client
      .from('expenses')
      .select(`
        *,
        participants:expense_participants(*)
      `)
      .eq('group_id', groupId)
      .is('deleted_at', null)
      .order('expense_date', { ascending: false });

    // Aplicar filtros
    if (filters) {
      if (filters.payer_id) {
        query = query.eq('payer_id', filters.payer_id);
      }
      if (filters.category) {
        query = query.eq('category', filters.category);
      }
      if (filters.start_date) {
        query = query.gte('expense_date', filters.start_date);
      }
      if (filters.end_date) {
        query = query.lte('expense_date', filters.end_date);
      }
    }

    const { data: expenses, error } = await query;

    if (error) {
      throw new BadRequestException(`Erro ao buscar despesas: ${error.message}`);
    }

    // Filtrar por participante se especificado
    if (filters?.participant_id) {
      return expenses.filter(expense =>
        expense.participants.some((p: ExpenseParticipant) => p.user_id === filters.participant_id)
      );
    }

    return expenses || [];
  }

  private async validateGroupMembership(groupId: string, userId: string): Promise<void> {
    const { data: membership, error } = await this.supabaseService.client
      .from('group_members')
      .select('id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (error || !membership) {
      throw new ForbiddenException('Usuário não é membro do grupo');
    }
  }
}