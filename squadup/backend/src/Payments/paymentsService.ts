import { Injectable, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { Payment } from './paymentModel';
import { SettleUpTransaction } from './dto/settle-up-transaction.dto';
import { ExpensesService } from '../Expenses/expensesService';
import { settleUp } from '../Expenses/ledger';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly expensesService: ExpensesService,
  ) { }

  /**
   * Register a payment. Balances are derived from expenses minus payments.
   */
  async registerPayment(
    createPaymentDto: CreatePaymentDto,
    userId: string,
    token: string,
  ): Promise<Payment> {
    const client = this.supabaseService.getClientWithToken(token);
    const { groupId, toUserId, amount, expenseId } = createPaymentDto;

    // Validate that user is a member of the group
    const { data: membership, error: memberError } = await client
      .from('group_members')
      .select('user_id')
      .eq('group_id', groupId)
      .eq('user_id', userId)
      .single();

    if (memberError || !membership) {
      throw new ForbiddenException('You are not a member of this group');
    }

    // Validate that toUserId is also a member
    const { data: receiverMembership, error: receiverError } = await client
      .from('group_members')
      .select('user_id')
      .eq('group_id', groupId)
      .eq('user_id', toUserId)
      .single();

    if (receiverError || !receiverMembership) {
      throw new BadRequestException('Receiver is not a member of this group');
    }

    // Validate that user is not paying themselves
    if (userId === toUserId) {
      throw new BadRequestException('Cannot pay yourself');
    }

    // Pagamentos só entram no saldo (não alteram as partes das despesas), por isso
    // basta garantir um valor em cêntimos.
    if (Math.round(amount * 100) / 100 !== amount) {
      throw new BadRequestException('Amount must have at most 2 decimal places');
    }

    // Insert payment record
    const { data: payment, error: paymentError } = await client
      .from('payments')
      .insert({
        group_id: groupId,
        from_user_id: userId,
        to_user_id: toUserId,
        amount: amount,
        expense_id: expenseId || null,
      })
      .select()
      .single();

    if (paymentError) {
      this.logger.error(`Error creating payment: ${paymentError.message}`);
      throw new BadRequestException('Failed to register payment');
    }

    this.logger.log(`Payment registered: ${userId} paid ${amount} to ${toUserId} in group ${groupId}`);
    return payment;
  }

  /**
   * Get payment history for a group
   */
  async getGroupPayments(groupId: string, token: string): Promise<Payment[]> {
    const client = this.supabaseService.getClientWithToken(token);

    const { data: payments, error } = await client
      .from('payments')
      .select('*')
      .eq('group_id', groupId)
      .order('payment_date', { ascending: false });

    if (error) {
      this.logger.error(`Error fetching payments: ${error.message}`);
      throw new BadRequestException('Failed to fetch payment history');
    }

    return payments || [];
  }

  /**
   * Calculate minimum transactions needed to settle up all debts in a group
   */
  async calculateSettleUpTransactions(
    groupId: string,
    userId: string,
    token: string,
  ): Promise<SettleUpTransaction[]> {
    // Get current balances for all group members
    const balances = await this.expensesService.getGroupBalance(groupId, userId, token);

    const transactions: SettleUpTransaction[] = settleUp(balances);

    this.logger.log(`Calculated ${transactions.length} settle-up transactions for group ${groupId}`);
    return transactions;
  }
}
