import { IsString, IsNotEmpty } from 'class-validator';

export class UpdateAvatarDto {
  @IsNotEmpty({ message: 'Avatar URL is required' })
  @IsString({ message: 'Avatar URL must be a string' })
  avatar_url: string;
}