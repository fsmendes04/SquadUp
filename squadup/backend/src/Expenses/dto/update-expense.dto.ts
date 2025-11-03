import {
  IsOptional,
  IsString,
  IsNumber,
  IsArray,
  IsUUID,
  IsDateString,
  Min,
  Max,
  MaxLength,
  ArrayMinSize,
  ArrayMaxSize
} from 'class-validator';

export class UpdateExpenseDto {
  @IsOptional()
  @IsNumber({}, { message: 'Amount must be a number' })
  @Min(0.01, { message: 'Amount must be at least 0.01' })
  @Max(999999.99, { message: 'Amount cannot exceed 999999.99' })
  amount?: number;

  @IsOptional()
  @IsString({ message: 'Description must be a string' })
  @MaxLength(500, { message: 'Description cannot exceed 500 characters' })
  description?: string;

  @IsOptional()
  @IsString({ message: 'Category must be a string' })
  @MaxLength(100, { message: 'Category cannot exceed 100 characters' })
  category?: string;

  @IsOptional()
  @IsDateString({}, { message: 'Invalid expense date format' })
  expense_date?: string;

  @IsOptional()
  @IsArray({ message: 'Participant IDs must be an array' })
  @ArrayMinSize(1, { message: 'At least one participant is required' })
  @ArrayMaxSize(50, { message: 'Cannot have more than 50 participants' })
  @IsUUID('4', { each: true, message: 'Invalid participant ID format' })
  participant_ids?: string[];
}