import { IsString, IsOptional } from 'class-validator';

export class UpdateProfileDto {
  @IsOptional()
  @IsString({ message: 'Name must be a string' })
  name?: string;
}