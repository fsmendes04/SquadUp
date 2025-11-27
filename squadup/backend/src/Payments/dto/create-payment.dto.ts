import { IsUUID, IsNumber, Min, IsOptional } from 'class-validator';

export class CreatePaymentDto {
  @IsUUID()
  groupId: string;

  @IsUUID()
  toUserId: string;

  @IsNumber()
  @Min(0.01, { message: 'Amount must be greater than 0' })
  amount: number;

  @IsUUID()
  @IsOptional()
  expenseId?: string;
}
