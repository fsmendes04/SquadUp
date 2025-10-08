import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './appController';
import { AppService } from './appService';
import { AuthModule } from './User/user.module';
import { GroupsModule } from './Groups/groups.module';
import { ExpensesModule } from './Expenses/expenses.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    AuthModule,
    GroupsModule,
    ExpensesModule
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule { }
