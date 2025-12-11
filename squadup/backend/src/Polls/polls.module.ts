import { Module } from '@nestjs/common';
import { PollsController } from './pollsController';
import { PollsService } from './pollsService';
import { SupabaseService } from '../Supabase/supabaseService';
import { UserModule } from '../User/user.module';
import { GroupsModule } from '../Groups/groups.module';

@Module({
  imports: [UserModule, GroupsModule],
  controllers: [PollsController],
  providers: [PollsService, SupabaseService],
  exports: [PollsService],
})
export class PollsModule { }