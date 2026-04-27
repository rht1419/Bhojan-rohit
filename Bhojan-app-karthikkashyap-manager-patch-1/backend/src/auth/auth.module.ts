import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { AuthController } from './controllers/auth.controller.js';
import { AuthService } from './services/auth.service.js';
import { ProfileService } from './services/profile.service.js';
import { PasswordService } from './services/password.service.js';
import { ContactService } from './services/contact.service.js';
import { UpgradeService } from './services/upgrade.service.js';
import { DeletionService } from './services/deletion.service.js';
import { TokenService } from './services/jwt.service.js';
import { JwtStrategy } from './strategies/jwt.strategy.js';
import { GoogleStrategy } from './strategies/google.strategy.js';
import { OtpModule } from '../otp/otp.module.js';
import { AuditModule } from '../audit/audit.module.js';

@Module({
  imports: [
    PassportModule,
    JwtModule.register({}),
    OtpModule,
    AuditModule,
  ],
  controllers: [AuthController],
  providers: [AuthService, ProfileService, PasswordService, ContactService, UpgradeService, DeletionService, TokenService, JwtStrategy, GoogleStrategy],
  exports: [TokenService, AuthService],
})
export class AuthModule {}
