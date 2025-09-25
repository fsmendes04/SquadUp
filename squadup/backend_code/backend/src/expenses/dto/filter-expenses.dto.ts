import { IsOptional, IsUUID, IsDateString, IsString } from 'class-validator';

export class FilterExpensesDto {
  @IsOptional()
  @IsUUID()
  payer_id?: string;

  @IsOptional()
  @IsUUID()
  participant_id?: string;

  @IsOptional()
  @IsDateString()
  start_date?: string;

  @IsOptional()
  @IsDateString()
  end_date?: string;

  @IsOptional()
  @IsString()
  category?: string;
}