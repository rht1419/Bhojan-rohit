import { Controller, Post, Put, Body, Req, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import { VendorService } from '../services/vendor.service.js';
import { VendorActivateDto } from '../dto/vendor-activate.dto.js';
import { VendorLoginDto } from '../dto/vendor-login.dto.js';
import { VendorProfileUpdateDto } from '../dto/vendor-profile-update.dto.js';
<<<<<<< HEAD
import { VendorSelfRegisterDto } from '../dto/vendor-self-register.dto.js';
import { VendorRequestOtpDto } from '../dto/vendor-request-otp.dto.js';
import { VendorVerifyOtpDto } from '../dto/vendor-verify-otp.dto.js';
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
import { JwtAuthGuard } from '../../auth/guards/jwt.guard.js';
import { RolesGuard } from '../../auth/guards/roles.guard.js';
import { Roles } from '../../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import type { JwtPayload } from '../../auth/services/jwt.service.js';
import { Role } from '@prisma/client';

@Controller('vendor/auth')
export class VendorController {
  constructor(private vendor: VendorService) {}

<<<<<<< HEAD
  // Self-registration — public
  @Post('register')
  @HttpCode(HttpStatus.OK)
  selfRegister(@Body() dto: VendorSelfRegisterDto) {
    return this.vendor.selfRegister(dto);
  }

  @Post('request-otp')
  @HttpCode(HttpStatus.OK)
  requestOtp(@Body() dto: VendorRequestOtpDto) {
    return this.vendor.requestRegistrationOtp(dto);
  }

  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  verifyOtp(@Body() dto: VendorVerifyOtpDto, @Req() req: Request) {
    return this.vendor.verifyRegistrationOtp(dto, req.ip, req.headers['user-agent']);
  }

=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  // EP-17
  @Post('activate')
  @HttpCode(HttpStatus.OK)
  activate(@Body() dto: VendorActivateDto) {
    return this.vendor.activate(dto);
  }

  // EP-18
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: VendorLoginDto, @Req() req: Request) {
    return this.vendor.login(dto, req.ip, req.headers['user-agent']);
  }

  // EP-19
  @Put('profile')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.VENDOR)
  updateProfile(@CurrentUser() user: JwtPayload, @Body() dto: VendorProfileUpdateDto) {
    return this.vendor.updateProfile(user.sub, dto);
  }
}
