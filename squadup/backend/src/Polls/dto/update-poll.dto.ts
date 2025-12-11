import {
  IsOptional,
  IsString,
  IsEnum,
  IsUUID,
  MaxLength
} from 'class-validator';

export type PollStatus = 'active' | 'closed';

export class UpdatePollDto {
  @IsOptional()
  @IsString({ message: 'Title must be a string' })
  @MaxLength(255, { message: 'Title cannot exceed 255 characters' })
  title?: string;

  @IsOptional()
  @IsEnum(['active', 'closed'], { message: 'Status must be either active or closed' })
  status?: PollStatus;

  @IsOptional()
  @IsUUID('4', { message: 'Invalid correct option ID format' })
  correct_option_id?: string;
}