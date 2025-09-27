import { IsString, IsOptional, IsArray } from 'class-validator';

export class UpdateGroupDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsString()
  @IsOptional()
  avatar_url?: string | null;

  @IsArray()
  @IsOptional()
  memberIds?: string[];
}