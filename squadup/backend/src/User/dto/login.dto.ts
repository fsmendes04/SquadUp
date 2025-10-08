import { IsEmail, IsString } from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: 'Email should be a valid email address' })
  email: string;

  @IsString({ message: 'Password must be a string' })
  password: string;
}