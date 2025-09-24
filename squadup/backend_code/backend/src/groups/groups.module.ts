import { Module } from '@nestjs/common';
import { GroupsController } from './groups.controller';
import { GroupsService } from './groups.service';
import { SupabaseService } from '../supabase/supabase.service';

@Module({
  controllers: [GroupsController],
  providers: [GroupsService, SupabaseService],
  exports: [GroupsService],
})
export class GroupsModule { }