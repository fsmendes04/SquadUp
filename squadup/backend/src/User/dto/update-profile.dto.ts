import { IsString, IsOptional, IsUrl } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString({ message: 'Name must be a string' })
  name?: string;

  @IsOptional()
  @IsUrl({}, { message: 'Avatar URL must be a valid URL' })
  avatar_url?: string;
}