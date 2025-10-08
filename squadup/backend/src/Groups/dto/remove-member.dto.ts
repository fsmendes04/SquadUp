import { IsString, IsNotEmpty } from 'class-validator';

export class RemoveMemberDto {
  @IsString()
  @IsNotEmpty()
  userId: string;
}