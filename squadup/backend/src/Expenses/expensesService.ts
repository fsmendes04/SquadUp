import { Injectable, NotFoundException, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { GroupsService } from '../Groups/groupsService';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { FilterExpensesDto } from './dto/filter-expenses.dto';
import { ExpenseWithParticipants } from './expenseModel';
import * as DOMPurify from 'isomorphic-dompurify';

@Injectable()
export class ExpensesService {
  private readonly logger = new Logger(ExpensesService.name);
  private readonly MAX_DESCRIPTION_LENGTH = 500;
  private readonly MAX_CATEGORY_LENGTH = 100;
  private readonly MAX_PARTICIPANTS = 50;
  private readonly MAX_AMOUNT = 999999.99;

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly groupsService: GroupsService,
  ) { }

  async createExpense(createExpenseDto: CreateExpenseDto, userId: string, token: string): Promise<ExpenseWithParticipants> {
    try {
      const { group_id, payer_id, amount, description, category, expense_date, participant_ids } = createExpenseDto;

      if (!group_id || !payer_id) {
        throw new BadRequestException('Group ID and Payer ID are required');
      }

      if (amount <= 0 || amount > this.MAX_AMOUNT) {
        throw new BadRequestException(`Amount must be between 0.01 and ${this.MAX_AMOUNT}`);
      }

      if (!participant_ids || participant_ids.length === 0) {
        throw new BadRequestException('At least one participant is required');
      }

      if (participant_ids.length > this.MAX_PARTICIPANTS) {
        throw new BadRequestException(`Cannot have more than ${this.MAX_PARTICIPANTS} participants`);
      }

      // Verificar duplicatas
      const uniqueParticipants = new Set(participant_ids);
      if (uniqueParticipants.size !== participant_ids.length) {
        throw new BadRequestException('Duplicate participant IDs are not allowed');
      }

      const sanitizedDescription = this.sanitizeString(description);
      const sanitizedCategory = this.sanitizeString(category);

      if (!sanitizedDescription || sanitizedDescription.length === 0) {
        throw new BadRequestException('Description cannot be empty');
      }

      if (sanitizedDescription.length > this.MAX_DESCRIPTION_LENGTH) {
        throw new BadRequestException(`Description cannot exceed ${this.MAX_DESCRIPTION_LENGTH} characters`);
      }

      if (!sanitizedCategory || sanitizedCategory.length === 0) {
        throw new BadRequestException('Category cannot be empty');
      }

      if (sanitizedCategory.length > this.MAX_CATEGORY_LENGTH) {
        throw new BadRequestException(`Category cannot exceed ${this.MAX_CATEGORY_LENGTH} characters`);
      }

      await this.validateGroupMembership(group_id, userId, token);
      await this.validateGroupMembership(group_id, payer_id, token);

      for (const participantId of participant_ids) {
        await this.validateGroupMembership(group_id, participantId, token);
      }

      const participantsWithoutPayer = participant_ids.filter(id => id !== payer_id);
      const amountPerParticipant = amount / participant_ids.length;

      const client = this.supabaseService.getClientWithToken(token);
      const { data: expense, error: expenseError } = await client
        .from('expenses')
        .insert({
          group_id,
          payer_id,
          amount,
          description: sanitizedDescription,
          category: sanitizedCategory,
          expense_date,
        })
        .select()
        .single();

      if (expenseError) {
        this.logger.error(`Failed to create expense for group ${group_id}`, expenseError.message);
        throw new BadRequestException('Unable to create expense');
      }

      const participantsData = participantsWithoutPayer.map(participantId => ({
        expense_id: expense.id,
        topayid: participantId,
        toreceiveid: payer_id,
        amount: amountPerParticipant,
      }));

      if (participantsData.length === 0) {
        return this.getExpenseById(expense.id, userId, token);
      }

      const { error: participantsError } = await client
        .from('expense_participants')
        .insert(participantsData);

      if (participantsError) {
        await client
          .from('expenses')
          .delete()
          .eq('id', expense.id);

        throw new BadRequestException('Unable to add participants');
      }

      return this.getExpenseById(expense.id, userId, token);
    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException) {
        throw error;
      }
      throw new BadRequestException('Failed to create expense');
    }
  }

  async updateExpense(expenseId: string, updateExpenseDto: UpdateExpenseDto, userId: string, token: string): Promise<ExpenseWithParticipants> {
    try {
      // Verificar se a despesa existe e se o usuário tem permissão
      const expense = await this.getExpenseById(expenseId, userId, token);

      // Verificar se o usuário é membro do grupo
      await this.validateGroupMembership(expense.group_id, userId, token);

      const updateData: any = { updated_at: new Date().toISOString() };

      // Validar e sanitizar dados
      if (updateExpenseDto.amount !== undefined) {
        if (updateExpenseDto.amount <= 0 || updateExpenseDto.amount > this.MAX_AMOUNT) {
          throw new BadRequestException(`Amount must be between 0.01 and ${this.MAX_AMOUNT}`);
        }
        updateData.amount = updateExpenseDto.amount;
      }

      if (updateExpenseDto.description !== undefined) {
        const sanitizedDescription = this.sanitizeString(updateExpenseDto.description);

        if (!sanitizedDescription || sanitizedDescription.length === 0) {
          throw new BadRequestException('Description cannot be empty');
        }

        if (sanitizedDescription.length > this.MAX_DESCRIPTION_LENGTH) {
          throw new BadRequestException(`Description cannot exceed ${this.MAX_DESCRIPTION_LENGTH} characters`);
        }

        updateData.description = sanitizedDescription;
      }

      if (updateExpenseDto.category !== undefined) {
        const sanitizedCategory = this.sanitizeString(updateExpenseDto.category);

        if (!sanitizedCategory || sanitizedCategory.length === 0) {
          throw new BadRequestException('Category cannot be empty');
        }

        if (sanitizedCategory.length > this.MAX_CATEGORY_LENGTH) {
          throw new BadRequestException(`Category cannot exceed ${this.MAX_CATEGORY_LENGTH} characters`);
        }

        updateData.category = sanitizedCategory;
      }

      if (updateExpenseDto.expense_date !== undefined) {
        updateData.expense_date = updateExpenseDto.expense_date;
      }

      if (Object.keys(updateData).length === 1) { // Apenas updated_at
        throw new BadRequestException('No valid fields to update');
      }

      const client = this.supabaseService.getClientWithToken(token);

      // Atualizar a despesa
      const { error: expenseError } = await client
        .from('expenses')
        .update(updateData)
        .eq('id', expenseId)
        .is('deleted_at', null);

      if (expenseError) {
        this.logger.error(`Failed to update expense ${expenseId}`, expenseError.message);
        throw new BadRequestException('Unable to update expense');
      }

      // Se houver novos participantes, atualizar
      if (updateExpenseDto.participant_ids) {
        if (updateExpenseDto.participant_ids.length === 0) {
          throw new BadRequestException('At least one participant is required');
        }

        if (updateExpenseDto.participant_ids.length > this.MAX_PARTICIPANTS) {
          throw new BadRequestException(`Cannot have more than ${this.MAX_PARTICIPANTS} participants`);
        }

        // Verificar duplicatas
        const uniqueParticipants = new Set(updateExpenseDto.participant_ids);
        if (uniqueParticipants.size !== updateExpenseDto.participant_ids.length) {
          throw new BadRequestException('Duplicate participant IDs are not allowed');
        }

        // Verificar se todos os participantes são membros do grupo
        for (const participantId of updateExpenseDto.participant_ids) {
          await this.validateGroupMembership(expense.group_id, participantId, token);
        }

        // Remover participantes existentes
        await client
          .from('expense_participants')
          .delete()
          .eq('expense_id', expenseId);

        // Calcular novo valor por participante
        const newAmount = updateExpenseDto.amount || expense.amount;
        const participantsWithoutPayer = updateExpenseDto.participant_ids.filter(id => id !== expense.payer_id);
        const amountPerParticipant = newAmount / updateExpenseDto.participant_ids.length;

        // Criar registros expense_participants apenas para quem deve ao pagador
        const participantsData = participantsWithoutPayer.map(participantId => ({
          expense_id: expenseId,
          topayid: participantId,
          toreceiveid: expense.payer_id,
          amount: amountPerParticipant,
        }));

        // LOG: Mostrar quanto cada participante deve/recebe
        participantsData.forEach(p => {
          this.logger.log(`[UPDATE] User ${p.topayid} deve ${p.amount.toFixed(2)} ao user ${p.toreceiveid}`);
        });

        // Apenas inserir se houver participantes (excluindo o caso onde o pagador é o único)
        if (participantsData.length > 0) {
          const { error: participantsError } = await client
            .from('expense_participants')
            .insert(participantsData);

          if (participantsError) {
            this.logger.error(`Failed to update participants for expense ${expenseId}`, participantsError.message);
            throw new BadRequestException('Unable to update participants');
          }
        }
      } else if (updateExpenseDto.amount) {
        // Se apenas o valor foi alterado, atualizar os valores dos participantes existentes
        const { data: participants } = await client
          .from('expense_participants')
          .select('*')
          .eq('expense_id', expenseId);

        if (participants && participants.length > 0) {
          // Contar total de participantes (incluindo o pagador)
          const totalParticipants = participants.length + 1; // +1 para o pagador
          const amountPerParticipant = updateExpenseDto.amount / totalParticipants;

          // Atualizar todos os participantes com o novo valor
          for (const participant of participants) {
            await client
              .from('expense_participants')
              .update({ amount: amountPerParticipant })
              .eq('id', participant.id);
          }
        }
      }

      this.logger.log(`Expense ${expenseId} updated successfully by user ${userId}`);
      return this.getExpenseById(expenseId, userId, token);
    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException || error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error('Unexpected error updating expense', error);
      throw new BadRequestException('Failed to update expense');
    }
  }

  async deleteExpense(expenseId: string, userId: string, token: string): Promise<void> {
    try {
      // Verificar se a despesa existe e se o usuário tem permissão
      const expense = await this.getExpenseById(expenseId, userId, token);

      // Verificar se o usuário é membro do grupo
      await this.validateGroupMembership(expense.group_id, userId, token);

      const client = this.supabaseService.getClientWithToken(token);

      // Soft delete
      const { error } = await client
        .from('expenses')
        .update({ deleted_at: new Date().toISOString() })
        .eq('id', expenseId)
        .is('deleted_at', null);

      if (error) {
        this.logger.error(`Failed to delete expense ${expenseId}`, error.message);
        throw new BadRequestException('Unable to delete expense');
      }

      this.logger.log(`Expense ${expenseId} deleted successfully by user ${userId}`);
    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException || error instanceof NotFoundException) {
        throw error;
      }
      this.logger.error('Unexpected error deleting expense', error);
      throw new BadRequestException('Failed to delete expense');
    }
  }

  async getExpenseById(expenseId: string, userId: string, token: string): Promise<ExpenseWithParticipants> {
    try {
      if (!expenseId) {
        throw new BadRequestException('Expense ID is required');
      }

      const client = this.supabaseService.getClientWithToken(token);
      const { data: expense, error } = await client
        .from('expenses')
        .select(`
          *,
          participants:expense_participants(*)
        `)
        .eq('id', expenseId)
        .is('deleted_at', null)
        .single();

      if (error || !expense) {
        throw new NotFoundException('Expense not found');
      }

      await this.validateGroupMembership(expense.group_id, userId, token);

      return expense;
    } catch (error) {
      if (error instanceof NotFoundException || error instanceof ForbiddenException || error instanceof BadRequestException) {
        throw error;
      }
      this.logger.error('Unexpected error fetching expense', error);
      throw new BadRequestException('Failed to fetch expense');
    }
  }

  async getExpensesByGroup(groupId: string, userId: string, filters: FilterExpensesDto | undefined, token: string): Promise<ExpenseWithParticipants[]> {
    try {
      if (!groupId) {
        throw new BadRequestException('Group ID is required');
      }

      await this.validateGroupMembership(groupId, userId, token);

      const client = this.supabaseService.getClientWithToken(token);
      let query = client
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
          const sanitizedCategory = this.sanitizeString(filters.category);
          if (sanitizedCategory) {
            query = query.eq('category', sanitizedCategory);
          }
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
        this.logger.error(`Failed to fetch expenses for group ${groupId}`, error.message);
        throw new BadRequestException('Unable to fetch expenses');
      }

      if (filters?.participant_id) {
        return expenses.filter(expense =>
          expense.participants.some((p: any) =>
            p.topayid === filters.participant_id || p.toreceiveid === filters.participant_id
          )
        );
      } return expenses || [];
    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException) {
        throw error;
      }
      this.logger.error('Unexpected error fetching expenses by group', error);
      throw new BadRequestException('Failed to fetch expenses');
    }
  }

  async getExpenseByCategory(groupId: string, category: string, userId: string, token: string): Promise<ExpenseWithParticipants[]> {
    try {
      if (!groupId) {
        throw new BadRequestException('Group ID is required');
      }
      if (!category) {
        throw new BadRequestException('Category is required');
      }

      // Validar se o usuário é membro do grupo
      await this.validateGroupMembership(groupId, userId, token);

      // Sanitizar categoria
      const sanitizedCategory = this.sanitizeString(category);
      if (!sanitizedCategory) {
        throw new BadRequestException('Invalid category');
      }

      const client = this.supabaseService.getClientWithToken(token);

      const { data: expenses, error } = await client
        .from('expenses')
        .select(`
          *,
          participants:expense_participants(*)
        `)
        .eq('group_id', groupId)
        .eq('category', sanitizedCategory)
        .is('deleted_at', null)
        .order('expense_date', { ascending: false });

      if (error) {
        this.logger.error(`Failed to fetch expenses by category for group ${groupId}`, error.message);
        throw new BadRequestException('Unable to fetch expenses by category');
      }

      return expenses || [];
    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException) {
        throw error;
      }
      this.logger.error('Unexpected error fetching expenses by category', error);
      throw new BadRequestException('Failed to fetch expenses by category');
    }
  }

  async getGroupBalance(groupId: string, userId: string, token: string): Promise<any[]> {
    try {
      if (!groupId) {
        throw new BadRequestException('Group ID is required');
      }

      // Verificar se o usuário é membro do grupo
      await this.validateGroupMembership(groupId, userId, token);

      // Buscar todos os membros do grupo usando GroupsService
      const members = await this.groupsService['getGroupMembers'](groupId, token);

      if (!members || members.length === 0) {
        this.logger.error(`No members found for group ${groupId}`);
        throw new BadRequestException('Unable to fetch group members');
      }

      const client = this.supabaseService.getClientWithToken(token);

      const { data: expenseIds, error: expenseIdsError } = await client
        .from('expenses')
        .select('id')
        .eq('group_id', groupId)
        .is('deleted_at', null);

      if (expenseIdsError) {
        this.logger.error(`Failed to fetch expenses for balance calculation ${groupId}`, expenseIdsError.message);
        throw new BadRequestException('Unable to fetch expenses for balance');
      }

      const ids = expenseIds.map((e: any) => e.id);

      // Buscar todos os participantes dessas despesas
      const { data: participants, error: participantsError } = await client
        .from('expense_participants')
        .select('topayid, toreceiveid, amount')
        .in('expense_id', ids);

      if (participantsError) {
        this.logger.error(`Failed to fetch participants for balance calculation ${groupId}`, participantsError.message);
        throw new BadRequestException('Unable to fetch participants for balance');
      }

      // Inicializar saldos para todos os membros
      const balances = new Map<string, { userId: string; name: string; balance: number }>();

      members.forEach((member: any) => {
        this.logger.log(`UserID: ${member.user_id}, Name: ${member.name}`);
        balances.set(member.user_id, {
          userId: member.user_id,
          name: member.name || 'Usuário',
          balance: 0,
        });
      });

      // Calcular saldos: quem deve paga (negativo), quem recebe (positivo)
      participants.forEach((participant: any) => {
        const payerBalance = balances.get(participant.topayid);
        const receiverBalance = balances.get(participant.toreceiveid);

        if (payerBalance) {
          payerBalance.balance -= participant.amount; // Quem paga tem saldo negativo
        }
        if (receiverBalance) {
          receiverBalance.balance += participant.amount; // Quem recebe tem saldo positivo
        }
      });      // Converter para o formato esperado
      const result = Array.from(balances.values()).map(balance => {
        return {
          userId: balance.userId,
          name: balance.name,
          toReceive: balance.balance > 0 ? Number(balance.balance.toFixed(2)) : 0,
          toPay: balance.balance < 0 ? Number(Math.abs(balance.balance).toFixed(2)) : 0,
        };
      });

      return result;
    } catch (error) {
      if (error instanceof BadRequestException || error instanceof ForbiddenException) {
        throw error;
      }
      this.logger.error('Unexpected error calculating group balance', error);
      throw new BadRequestException('Failed to calculate group balance');
    }
  }

  private async validateGroupMembership(groupId: string, userId: string, token: string): Promise<void> {
    try {
      const client = this.supabaseService.getClientWithToken(token);

      // Debug: Log what we're checking
      this.logger.debug(`Validating membership: groupId=${groupId}, userId=${userId}`);

      // Debug: Verify token and get auth.uid()
      const { data: { user }, error: authError } = await client.auth.getUser();
      if (authError || !user) {
        this.logger.error(`Token verification failed: ${authError?.message || 'User not found'}`);
        throw new ForbiddenException('Invalid authentication token');
      }
      this.logger.debug(`Token auth.uid() = ${user.id}`);

      const { data: memberships, error } = await client
        .from('group_members')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId);

      if (error || !memberships || memberships.length === 0) {
        this.logger.error(`Membership check failed: groupId=${groupId}, userId=${userId}, error=${error?.message}`);
        throw new ForbiddenException('User is not a member of this group');
      }

      this.logger.debug(`Membership validated successfully for user ${userId} in group ${groupId}`);
    } catch (error) {
      if (error instanceof ForbiddenException) {
        throw error;
      }
      this.logger.error('Error validating group membership', error);
      throw new ForbiddenException('Unable to verify group membership');
    }
  }

  private sanitizeString(input: string): string {
    if (!input) return '';
    const cleaned = DOMPurify.sanitize(input, {
      ALLOWED_TAGS: [],
      ALLOWED_ATTR: []
    });
    return cleaned.trim();
  }
}