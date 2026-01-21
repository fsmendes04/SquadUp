import { IsString, IsNotEmpty, IsEmail } from 'class-validator';

export class AddMemberDto {
  @IsString()
  @IsNotEmpty({ message: 'User email is required' })
  @IsEmail({}, { message: 'User email must be a valid email address' })
  userEmail: string;
}