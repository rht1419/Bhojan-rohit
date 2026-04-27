import { Controller, Post, Get, Body, Req, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import type { Request } from 'express';
import { AdminAuthService } from '../services/admin-auth.service.js';
import { AdminLoginDto } from '../dto/admin-login.dto.js';
import { JwtAuthGuard } from '../../auth/guards/jwt.guard.js';
import { RolesGuard } from '../../auth/guards/roles.guard.js';
import { Roles } from '../../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import type { JwtPayload } from '../../auth/services/jwt.service.js';
import { Role } from '@prisma/client';

@Controller('admin/auth')
export class AdminAuthController {
  constructor(private adminAuth: AdminAuthService) {}

  // EP-20 — step 1: POST with only email → sends OTP
  //         step 2: POST with email + otp → verifies + issues tokens
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: AdminLoginDto, @Req() req: Request) {
    return this.adminAuth.login(dto, req.ip, req.headers['user-agent']);
  }

  // EP-21
  @Get('permissions')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN, Role.TECH_ADMIN)
  getPermissions(@CurrentUser() user: JwtPayload) {
    return this.adminAuth.getPermissions(user.sub, user.role as Role);
  }
}
