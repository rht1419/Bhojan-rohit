import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { VendorController } from './controllers/vendor.controller.js';
import { VendorService } from './services/vendor.service.js';
import { AuthModule } from '../auth/auth.module.js';
import { AuditModule } from '../audit/audit.module.js';
<<<<<<< HEAD
import { OtpModule } from '../otp/otp.module.js';

@Module({
  imports: [JwtModule.register({}), AuthModule, AuditModule, OtpModule],
=======

@Module({
  imports: [JwtModule.register({}), AuthModule, AuditModule],
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  controllers: [VendorController],
  providers: [VendorService],
})
export class VendorModule {}
