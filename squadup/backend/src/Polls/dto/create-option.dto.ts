import {
  IsNotEmpty,
  IsString,
  IsUUID,
  MaxLength
} from 'class-validator';

export class CreateOptionDto {
  @IsNotEmpty({ message: 'Poll ID is required' })
  @IsUUID('4', { message: 'Invalid poll ID format' })
  poll_id: string;

  @IsNotEmpty({ message: 'Option text is required' })
  @IsString({ message: 'Option text must be a string' })
  @MaxLength(255, { message: 'Option text cannot exceed 255 characters' })
  text: string;
}
