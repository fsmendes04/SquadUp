import { Controller, Post, Get, Body, Param, UseGuards } from '@nestjs/common';
import { PaymentsService } from './paymentsService';
import { CreatePaymentDto } from './dto/create-payment.dto';
import { Payment } from './paymentModel';
import { AuthGuard } from '../User/userToken';
import { CurrentUser, GetToken } from '../common/decorators';

@Controller('payments')
@UseGuards(AuthGuard)
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) { }

  /**
   * Register a new payment
   * POST /payments
   */
  @Post()
  async registerPayment(
    @Body() createPaymentDto: CreatePaymentDto,
    @CurrentUser() user: any,
    @GetToken() token: string,
  ): Promise<Payment> {
    return this.paymentsService.registerPayment(createPaymentDto, user.id, token);
  }

  /**
   * Get all payments for a group
   * GET /payments/group/:groupId
   */
  @Get('group/:groupId')
  async getGroupPayments(
    @Param('groupId') groupId: string,
    @GetToken() token: string,
  ): Promise<Payment[]> {
    return this.paymentsService.getGroupPayments(groupId, token);
  }
}
