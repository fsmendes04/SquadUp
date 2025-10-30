import { Module } from '@nestjs/common';
import { UserService } from './userService';
import { UserController } from './userController';
import { SessionService } from './sessionService';
import { SupabaseService } from '../Supabase/supabaseService';

@Module({
  controllers: [UserController],
  providers: [UserService, SessionService, SupabaseService],
  exports: [UserService, SessionService],
})
export class UserModule { }