import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { UserModule } from './User/user.module';
import { GroupsModule } from './Groups/groups.module';
import { ExpensesModule } from './Expenses/expenses.module';
import { GalleryModule } from './Gallery/gallery.module';
import { PaymentsModule } from './Payments/payments.module';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { validateEnvironment } from './common/config/envValidation';
import { SecurityHeadersMiddleware } from './common/middleware/securityHeaders';
import { RequestLoggingMiddleware } from './common/middleware/logger';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
      validate: validateEnvironment,
    }),
    ThrottlerModule.forRoot([{
      ttl: 60000,
      limit: 100,
    }]),
    UserModule,
    GroupsModule,
    ExpensesModule,
    GalleryModule,
    PaymentsModule
  ],
  controllers: [],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(SecurityHeadersMiddleware, RequestLoggingMiddleware)
      .forRoutes('*');
  }
}