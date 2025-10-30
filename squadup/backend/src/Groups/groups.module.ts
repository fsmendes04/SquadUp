import { Module } from '@nestjs/common';
import { GroupsController } from './groupsController';
import { GroupsService } from './groupsService';
import { SupabaseService } from '../Supabase/supabaseService';
import { UserModule } from '../User/user.module';

@Module({
  imports: [UserModule],
  controllers: [GroupsController],
  providers: [GroupsService, SupabaseService],
  exports: [GroupsService],
})
export class GroupsModule { }