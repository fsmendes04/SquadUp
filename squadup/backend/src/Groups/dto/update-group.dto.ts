import { IsString, IsOptional, MaxLength } from 'class-validator';

export class UpdateGroupDto {
  @IsString()
  @IsOptional()
  @MaxLength(100, { message: 'Group name cannot exceed 100 characters' })
  name?: string;

  @IsString()
  @IsOptional()
  avatar_url?: string | null;
}