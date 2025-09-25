import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { SupabaseService } from '../supabase/supabase.service';
import { UploadModule } from '../upload/upload.module';

@Module({
  imports: [UploadModule],
  controllers: [AuthController],
  providers: [AuthService, SupabaseService],
  exports: [AuthService],
})
export class AuthModule { }