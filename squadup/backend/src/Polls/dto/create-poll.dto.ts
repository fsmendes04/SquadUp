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
  IsDateString,
  IsObject,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export type PollType = 'voting' | 'betting';

export class RewardDto {
  @IsOptional()
  amount?: number;

  @IsOptional()
  @IsString()
  text?: string;
}

export class PollOptionDto {
  @IsNotEmpty({ message: 'Option text is required' })
  @IsString({ message: 'Option text must be a string' })
  @MaxLength(255, { message: 'Option text cannot exceed 255 characters' })
  text: string;

  @IsOptional()
  @IsObject({ message: 'Proposer reward must be an object' })
  @ValidateNested()
  @Type(() => RewardDto)
  proposer_reward?: RewardDto;

  @IsOptional()
  @IsObject({ message: 'Challenger reward must be an object' })
  @ValidateNested()
  @Type(() => RewardDto)
  challenger_reward?: RewardDto;

  @IsOptional()
  @IsUUID('4', { message: 'Invalid challenger user ID format' })
  challenger_user_id?: string;
}

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
  @ValidateNested({ each: true })
  @Type(() => PollOptionDto)
  options: PollOptionDto[];

  @IsOptional()
  @IsDateString({}, { message: 'Invalid date format for closed_at' })
  closed_at?: string;
}