import { Module } from '@nestjs/common';
import { ExpensesController } from './expenses.controller';
import { ExpensesService } from './expenses.service';
import { SupabaseService } from '../Supabase/supabaseService';
import { UserModule } from '../User/user.module';

@Module({
  imports: [UserModule],
  controllers: [ExpensesController],
  providers: [ExpensesService, SupabaseService],
  exports: [ExpensesService],
})
export class ExpensesModule { }