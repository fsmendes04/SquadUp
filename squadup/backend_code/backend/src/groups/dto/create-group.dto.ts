import { IsString, IsNotEmpty, IsOptional, IsArray } from 'class-validator';

export class CreateGroupDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsArray()
  @IsOptional()
  memberIds?: string[];
}