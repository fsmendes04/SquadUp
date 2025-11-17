import { IsString, MinLength, Matches } from 'class-validator';

export class ChangePasswordDto {
  @IsString()
  currentPassword: string;

  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[A-Za-z\d]{8,}$/,
    { message: 'Password must be at least 8 characters and contain uppercase, lowercase, and number.' })
  newPassword: string;

  @IsString()
  confirmNewPassword: string;
}
