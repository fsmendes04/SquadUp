import { IsString, IsOptional, IsArray } from 'class-validator';

export class UpdateGroupDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsArray()
  @IsOptional()
  memberIds?: string[];
}