import { IsString, IsNotEmpty, IsUUID } from 'class-validator';

export class AddMemberDto {
  @IsString()
  @IsNotEmpty({ message: 'User ID is required' })
  @IsUUID('4', { message: 'User ID must be a valid UUID' })
  userId: string;
}