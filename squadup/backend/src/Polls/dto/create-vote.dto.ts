import {
  IsNotEmpty,
  IsUUID
} from 'class-validator';

export class CreateVoteDto {
  @IsNotEmpty({ message: 'Poll ID is required' })
  @IsUUID('4', { message: 'Invalid poll ID format' })
  poll_id: string;

  @IsNotEmpty({ message: 'Option ID is required' })
  @IsUUID('4', { message: 'Invalid option ID format' })
  option_id: string;

  @IsNotEmpty({ message: 'User ID is required' })
  @IsUUID('4', { message: 'Invalid user ID format' })
  user_id: string;
}
