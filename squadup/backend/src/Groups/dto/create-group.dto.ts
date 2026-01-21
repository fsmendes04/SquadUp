import { IsString, IsNotEmpty, IsOptional, IsArray, MaxLength, ArrayUnique, IsEmail } from 'class-validator';

export class CreateGroupDto {
  @IsString()
  @IsNotEmpty({ message: 'Group name is required' })
  @MaxLength(100, { message: 'Group name cannot exceed 100 characters' })
  name: string;

  @IsString()
  @IsOptional()
  avatar_url?: string | null;

  @IsArray({ message: 'Member emails must be an array' })
  @IsEmail({}, { each: true, message: 'Each member email must be a valid email address' })
  @ArrayUnique({ message: 'Member emails must be unique' })
  @IsOptional()
  memberEmails?: string[];
}