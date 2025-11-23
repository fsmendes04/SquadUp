import { Module } from '@nestjs/common';
import { ExpensesController } from './expensesController';
import { ExpensesService } from './expensesService';
import { SupabaseService } from '../Supabase/supabaseService';
import { UserModule } from '../User/user.module';
import { GroupsModule } from '../Groups/groups.module';

@Module({
  imports: [UserModule, GroupsModule],
  controllers: [ExpensesController],
  providers: [ExpensesService, SupabaseService],
  exports: [ExpensesService],
})
export class ExpensesModule { }