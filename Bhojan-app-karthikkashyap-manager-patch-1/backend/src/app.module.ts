import { Module, MiddlewareConsumer } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { BullModule } from '@nestjs/bull';
import { ScheduleModule } from '@nestjs/schedule';
import { PrismaModule } from './prisma/prisma.module.js';
import { RedisModule } from './redis/redis.module.js';
import { AuthModule } from './auth/auth.module.js';
import { TenantsModule } from './tenants/tenants.module.js';
import { AuditModule } from './audit/audit.module.js';
import { OtpModule } from './otp/otp.module.js';
import { VendorModule } from './vendor/vendor.module.js';
import { AdminModule } from './admin/admin.module.js';
import { TenantMiddleware } from './tenants/middleware/tenant.middleware.js';
import { JwtModule } from '@nestjs/jwt';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    JwtModule.register({ global: true }),
    // Bull queue — Redis-backed background job processing (bulk upload, audit export)
    BullModule.forRoot({
      redis: {
        host: process.env.REDIS_HOST ?? 'localhost',
        port: parseInt(process.env.REDIS_PORT ?? '6379', 10),
        password: process.env.REDIS_PASSWORD ?? undefined,
      },
    }),
    // Schedule module — enables @Cron decorators (delegation auto-revoke every 5 min)
    ScheduleModule.forRoot(),
    PrismaModule,
    RedisModule,
    OtpModule,
    AuditModule,
    AuthModule,
    TenantsModule,
    VendorModule,
    AdminModule,
  ],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(TenantMiddleware).forRoutes('*');
  }
}
