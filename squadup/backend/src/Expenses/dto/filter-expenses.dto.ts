import { IsOptional, IsUUID, IsDateString, IsString, MaxLength } from 'class-validator';

export class FilterExpensesDto {
  @IsOptional()
  @IsUUID('4', { message: 'Invalid payer ID format' })
  payer_id?: string;

  @IsOptional()
  @IsUUID('4', { message: 'Invalid participant ID format' })
  participant_id?: string;

  @IsOptional()
  @IsDateString({}, { message: 'Invalid start date format' })
  start_date?: string;

  @IsOptional()
  @IsDateString({}, { message: 'Invalid end date format' })
  end_date?: string;

  @IsOptional()
  @IsString({ message: 'Category must be a string' })
  @MaxLength(100, { message: 'Category cannot exceed 100 characters' })
  category?: string;
}