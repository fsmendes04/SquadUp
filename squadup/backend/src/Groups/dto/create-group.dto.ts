import { IsString, IsNotEmpty, IsOptional, IsArray, MaxLength, ArrayUnique, IsUUID } from 'class-validator';

export class CreateGroupDto {
  @IsString()
  @IsNotEmpty({ message: 'Group name is required' })
  @MaxLength(100, { message: 'Group name cannot exceed 100 characters' })
  name: string;

  @IsString()
  @IsOptional()
  avatar_url?: string | null;

  @IsArray({ message: 'Member IDs must be an array' })
  @IsUUID('4', { each: true, message: 'Each member ID must be a valid UUID' })
  @ArrayUnique({ message: 'Member IDs must be unique' })
  @IsOptional()
  memberIds?: string[];
}