import { IsString, IsNotEmpty, IsDateString } from 'class-validator';

export class CreateGalleryDto {
  @IsString()
  @IsNotEmpty()
  group_id: string;

  @IsString()
  @IsNotEmpty()
  event_name: string;

  @IsString()
  @IsNotEmpty()
  location: string;

  @IsDateString()
  @IsNotEmpty()
  date: string;
}
