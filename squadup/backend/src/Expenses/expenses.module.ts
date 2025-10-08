import { Module } from '@nestjs/common';
import { ExpensesController } from './expenses.controller';
import { ExpensesService } from './expenses.service';
import { SupabaseService } from '../supabase/supabaseService';
import { AuthModule } from '../User/user.module';

@Module({
  imports: [AuthModule],
  controllers: [ExpensesController],
  providers: [ExpensesService, SupabaseService],
  exports: [ExpensesService],
})
export class ExpensesModule { }