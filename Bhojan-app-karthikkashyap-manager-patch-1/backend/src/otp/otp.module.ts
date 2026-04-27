import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { OtpService } from './services/otp.service.js';

@Module({
  imports: [ConfigModule],
  providers: [OtpService],
  exports: [OtpService],
})
export class OtpModule {}
