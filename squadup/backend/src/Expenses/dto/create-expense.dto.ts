import {
  IsNotEmpty,
  IsString,
  IsNumber,
  IsUUID,
  IsArray,
  IsDateString,
  Min,
  Max,
  MaxLength,
  ArrayMinSize,
  ArrayMaxSize
} from 'class-validator';

export class CreateExpenseDto {
  @IsNotEmpty({ message: 'Group ID is required' })
  @IsUUID('4', { message: 'Invalid group ID format' })
  group_id: string;

  @IsNotEmpty({ message: 'Payer ID is required' })
  @IsUUID('4', { message: 'Invalid payer ID format' })
  payer_id: string;

  @IsNotEmpty({ message: 'Amount is required' })
  @IsNumber({}, { message: 'Amount must be a number' })
  @Min(0.01, { message: 'Amount must be at least 0.01' })
  @Max(999999.99, { message: 'Amount cannot exceed 999999.99' })
  amount: number;

  @IsNotEmpty({ message: 'Description is required' })
  @IsString({ message: 'Description must be a string' })
  @MaxLength(500, { message: 'Description cannot exceed 500 characters' })
  description: string;

  @IsNotEmpty({ message: 'Category is required' })
  @IsString({ message: 'Category must be a string' })
  @MaxLength(100, { message: 'Category cannot exceed 100 characters' })
  category: string;

  @IsNotEmpty({ message: 'Expense date is required' })
  @IsDateString({}, { message: 'Invalid expense date format' })
  expense_date: string;

  @IsNotEmpty({ message: 'Participant IDs are required' })
  @IsArray({ message: 'Participant IDs must be an array' })
  @ArrayMinSize(1, { message: 'At least one participant is required' })
  @ArrayMaxSize(50, { message: 'Cannot have more than 50 participants' })
  @IsUUID('4', { each: true, message: 'Invalid participant ID format' })
  participant_ids: string[];
}