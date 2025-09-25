import { IsOptional, IsString, IsNumber, IsArray, IsUUID, IsDateString, Min } from 'class-validator';

export class UpdateExpenseDto {
  @IsOptional()
  @IsNumber()
  @Min(0.01)
  amount?: number;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsDateString()
  expense_date?: string;

  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  participant_ids?: string[];
}