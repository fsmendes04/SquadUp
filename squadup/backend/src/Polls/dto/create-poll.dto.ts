import {
  IsNotEmpty,
  IsString,
  IsUUID,
  IsArray,
  IsEnum,
  MaxLength,
  ArrayMinSize,
  ArrayMaxSize,
  IsOptional,
  IsDateString
} from 'class-validator';

export type PollType = 'voting' | 'betting';

export class CreatePollDto {
  @IsNotEmpty({ message: 'Group ID is required' })
  @IsUUID('4', { message: 'Invalid group ID format' })
  group_id: string;

  @IsNotEmpty({ message: 'Title is required' })
  @IsString({ message: 'Title must be a string' })
  @MaxLength(255, { message: 'Title cannot exceed 255 characters' })
  title: string;

  @IsNotEmpty({ message: 'Poll type is required' })
  @IsEnum(['voting', 'betting'], { message: 'Poll type must be either voting or betting' })
  type: PollType;

  @IsNotEmpty({ message: 'Options are required' })
  @IsArray({ message: 'Options must be an array' })
  @ArrayMinSize(2, { message: 'At least 2 options are required' })
  @ArrayMaxSize(10, { message: 'Cannot have more than 10 options' })
  @IsString({ each: true, message: 'Each option must be a string' })
  @MaxLength(255, { each: true, message: 'Each option cannot exceed 255 characters' })
  options: string[];

  @IsOptional()
  @IsDateString({}, { message: 'Invalid date format for closed_at' })
  closed_at?: string;
}