import { Module } from '@nestjs/common';
import { PaymentsController } from './paymentsController';
import { PaymentsService } from './paymentsService';
import { SupabaseService } from '../Supabase/supabaseService';
import { UserModule } from '../User/user.module';
import { ExpensesModule } from '../Expenses/expenses.module';

@Module({
  imports: [UserModule, ExpensesModule],
  controllers: [PaymentsController],
  providers: [PaymentsService, SupabaseService],
  exports: [PaymentsService],
})
export class PaymentsModule { }
