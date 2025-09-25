import { IsString, IsOptional } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString({ message: 'Name must be a string' })
  name?: string;

  @IsOptional()
  @IsString({ message: 'Avatar URL must be a string' })
  avatar_url?: string;

  @IsOptional()
  @IsString({ message: 'Avatar path must be a string' })
  avatar_path?: string;
}