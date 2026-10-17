import { Injectable, NotFoundException, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { GroupsService } from '../Groups/groupsService';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { UpdateExpenseDto } from './dto/update-expense.dto';
import { FilterExpensesDto } from './dto/filter-expenses.dto';
import { ExpenseWithParticipants } from './expenseModel';
import xss from 'xss';
import { computeBalances, splitEvenly, toCents, MemberBalance, ParticipantRow, Share } from './ledger';

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
    const { group_id, payer_id, amount, description, category, expense_date, participant_ids } = createExpenseDto;

    const sanitizedDescription = this.validateDescription(description);
    const sanitizedCategory = this.validateCategory(category);
    const shares = this.buildShares(amount, participant_ids);

    const client = this.supabaseService.getClientWithToken(token);
    const { data: expenseId, error } = await client.rpc('create_expense', {
      p_group_id: group_id,
      p_payer_id: payer_id,
      p_amount: amount,
      p_description: sanitizedDescription,
      p_category: sanitizedCategory,
      p_expense_date: expense_date,
      p_shares: shares,
    });

    if (error) {
      this.logger.error(`Failed to create expense for group ${group_id}`, error.message);
      throw this.toHttpError(error, 'Unable to create expense');
    }

    return this.getExpenseById(expenseId, userId, token);
  }

  async updateExpense(expenseId: string, updateExpenseDto: UpdateExpenseDto, userId: string, token: string): Promise<ExpenseWithParticipants> {
    const expense = await this.getExpenseById(expenseId, userId, token);

    const description = updateExpenseDto.description !== undefined
      ? this.validateDescription(updateExpenseDto.description)
      : null;
    const category = updateExpenseDto.category !== undefined
      ? this.validateCategory(updateExpenseDto.category)
      : null;

    // As partes são recalculadas sempre que o valor ou os participantes mudam.
    const amount = updateExpenseDto.amount ?? Number(expense.amount);
    const amountChanged = updateExpenseDto.amount !== undefined && toCents(amount) !== toCents(expense.amount);
    const participantIds = updateExpenseDto.participant_ids
      ?? expense.participants.map((participant: any) => participant.topayid);
    const shares = amountChanged || updateExpenseDto.participant_ids
      ? this.buildShares(amount, participantIds)
      : null;

    if (!description && !category && !updateExpenseDto.expense_date && !shares && !amountChanged) {
      throw new BadRequestException('No valid fields to update');
    }

    const client = this.supabaseService.getClientWithToken(token);
    const { error } = await client.rpc('update_expense', {
      p_expense_id: expenseId,
      p_amount: amountChanged ? amount : null,
      p_description: description,
      p_category: category,
      p_expense_date: updateExpenseDto.expense_date ?? null,
      p_shares: shares,
    });

    if (error) {
      this.logger.error(`Failed to update expense ${expenseId}`, error.message);
      throw this.toHttpError(error, 'Unable to update expense');
    }

    this.logger.log(`Expense ${expenseId} updated successfully by user ${userId}`);
    return this.getExpenseById(expenseId, userId, token);
  }

  async deleteExpense(expenseId: string, userId: string, token: string): Promise<void> {
    const client = this.supabaseService.getClientWithToken(token);
    const { error } = await client.rpc('delete_expense', { p_expense_id: expenseId });

    if (error) {
      this.logger.error(`Failed to delete expense ${expenseId}`, error.message);
      throw this.toHttpError(error, 'Unable to delete expense');
    }

    this.logger.log(`Expense ${expenseId} deleted successfully by user ${userId}`);
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
          participants:expense_participants(
            id,
            expense_id,
            topayid,
            toreceiveid,
            amount,
            amount_paid,
            created_at
          )
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
          participants:expense_participants(
            id,
            expense_id,
            topayid,
            toreceiveid,
            amount,
            amount_paid,
            created_at
          )
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
          participants:expense_participants(
            id,
            expense_id,
            topayid,
            toreceiveid,
            amount,
            amount_paid,
            created_at
          )
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

  async getGroupBalance(groupId: string, userId: string, token: string): Promise<MemberBalance[]> {
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

      let participants: ParticipantRow[] = [];
      if (ids.length > 0) {
        const { data, error: participantsError } = await client
          .from('expense_participants')
          .select('topayid, toreceiveid, amount')
          .in('expense_id', ids);

        if (participantsError) {
          this.logger.error(`Failed to fetch participants for balance calculation ${groupId}`, participantsError.message);
          throw new BadRequestException('Unable to fetch participants for balance');
        }
        participants = data || [];
      }

      const { data: payments, error: paymentsError } = await client
        .from('payments')
        .select('from_user_id, to_user_id, amount')
        .eq('group_id', groupId);

      if (paymentsError) {
        this.logger.error(`Failed to fetch payments for balance calculation ${groupId}`, paymentsError.message);
        throw new BadRequestException('Unable to fetch payments for balance');
      }

      const result = computeBalances(members, participants, payments || []);

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

  private validateDescription(description: string): string {
    const sanitized = this.sanitizeString(description);
    if (!sanitized) {
      throw new BadRequestException('Description cannot be empty');
    }
    if (sanitized.length > this.MAX_DESCRIPTION_LENGTH) {
      throw new BadRequestException(`Description cannot exceed ${this.MAX_DESCRIPTION_LENGTH} characters`);
    }
    return sanitized;
  }

  private validateCategory(category: string): string {
    const sanitized = this.sanitizeString(category);
    if (!sanitized) {
      throw new BadRequestException('Category cannot be empty');
    }
    if (sanitized.length > this.MAX_CATEGORY_LENGTH) {
      throw new BadRequestException(`Category cannot exceed ${this.MAX_CATEGORY_LENGTH} characters`);
    }
    return sanitized;
  }

  private buildShares(amount: number, participantIds: string[]): Share[] {
    if (!participantIds || participantIds.length === 0) {
      throw new BadRequestException('At least one participant is required');
    }
    if (participantIds.length > this.MAX_PARTICIPANTS) {
      throw new BadRequestException(`Cannot have more than ${this.MAX_PARTICIPANTS} participants`);
    }
    if (new Set(participantIds).size !== participantIds.length) {
      throw new BadRequestException('Duplicate participant IDs are not allowed');
    }
    if (amount <= 0 || amount > this.MAX_AMOUNT) {
      throw new BadRequestException(`Amount must be between 0.01 and ${this.MAX_AMOUNT}`);
    }
    return splitEvenly(amount, participantIds);
  }

  // Erros das funções SQL: 42501 = sem permissão, P0002 = não encontrado, resto = validação.
  private toHttpError(error: { code?: string; message: string }, fallback: string) {
    if (error.code === '42501') {
      return new ForbiddenException(error.message);
    }
    if (error.code === 'P0002') {
      return new NotFoundException(error.message);
    }
    if (error.code === 'P0001') {
      return new BadRequestException(error.message);
    }
    return new BadRequestException(fallback);
  }

  private sanitizeString(input: string): string {
    if (!input) return '';
    return xss(input, {
      whiteList: {},
      stripIgnoreTag: true,
      stripIgnoreTagBody: ['script']
    }).trim();
  }
}