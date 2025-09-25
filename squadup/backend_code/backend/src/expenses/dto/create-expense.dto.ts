import { IsNotEmpty, IsString, IsNumber, IsUUID, IsArray, IsDateString, Min, IsOptional } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateExpenseDto {
  @IsNotEmpty()
  @IsUUID()
  group_id: string;

  @IsNotEmpty()
  @IsUUID()
  payer_id: string;

  @IsNotEmpty()
  @IsNumber()
  @Min(0.01)
  amount: number;

  @IsNotEmpty()
  @IsString()
  description: string;

  @IsNotEmpty()
  @IsString()
  category: string;

  @IsNotEmpty()
  @IsDateString()
  expense_date: string;

  @IsNotEmpty()
  @IsArray()
  @IsUUID('4', { each: true })
  participant_ids: string[];
}