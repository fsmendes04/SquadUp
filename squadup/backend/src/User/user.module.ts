import { Module } from '@nestjs/common';
import { UserService } from './userService';
import { AuthController } from './userController';
import { SupabaseService } from '../supabase/supabaseService';

@Module({
  controllers: [AuthController],
  providers: [UserService, SupabaseService],
  exports: [UserService],
})
export class AuthModule { }