import { Injectable, BadRequestException, ForbiddenException, Logger } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { Payment } from './paymentModel';
import { ExpenseParticipant } from '../Expenses/expenseModel';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(private readonly supabaseService: SupabaseService) { }

  /**
   * Register a payment and process settlement of expense participants
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

    // Process settlement of expense participants
    await this.processPaymentSettlement(userId, toUserId, groupId, amount, client);

    this.logger.log(`Payment registered: ${userId} paid ${amount} to ${toUserId} in group ${groupId}`);
    return payment;
  }

  /**
   * Process payment settlement by distributing the amount across expense participants
   * and deleting fully paid records
   */
  private async processPaymentSettlement(
    fromUserId: string,
    toUserId: string,
    groupId: string,
    amount: number,
    client: any,
  ): Promise<void> {
    let remaining = amount;

    // Fetch all unpaid or partially paid debts, ordered by creation date
    const { data: allDebts, error: debtsError } = await client
      .from('expense_participants')
      .select('*')
      .eq('topayid', fromUserId)
      .eq('toreceiveid', toUserId)
      .order('created_at', { ascending: true });

    if (debtsError) {
      this.logger.error(`Error fetching debts: ${debtsError.message}`);
      throw new BadRequestException('Failed to process payment settlement');
    }

    // Filter for unpaid or partially paid debts (amount_paid < amount)
    const debts = allDebts?.filter(debt => (debt.amount_paid || 0) < debt.amount) || [];


    if (debts.length === 0) {
      return;
    }

    // Process each debt
    for (const debt of debts as ExpenseParticipant[]) {
      if (remaining <= 0) break;

      const currentAmountPaid = debt.amount_paid || 0;
      const debtRemaining = debt.amount - currentAmountPaid;

      if (remaining >= debtRemaining) {
        // Fully pay this debt - delete the record
        const { data: deleteData, error: deleteError } = await client
          .from('expense_participants')
          .delete()
          .eq('id', debt.id)
          .select();

        if (deleteError) {
          this.logger.error(`Error deleting expense participant ${debt.id}: ${deleteError.message}`);
        } else {
          this.logger.log(`Expense participant ${debt.id} fully paid and deleted`);
        }

        remaining -= debtRemaining;
      } else if (remaining > 0) {
        // Partially pay this debt
        const newAmountPaid = currentAmountPaid + remaining;

        const { data: updateData, error: updateError } = await client
          .from('expense_participants')
          .update({ amount_paid: newAmountPaid })
          .eq('id', debt.id)
          .select();

        if (updateError) {
          this.logger.error(`Error updating expense participant ${debt.id}: ${updateError.message}`);
        } else {
        }

        remaining = 0;
      }
    }

    if (remaining > 0) {
      this.logger.warn(`Payment of ${amount} exceeded total debts. Remaining: ${remaining}`);
    }
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
}
