<<<<<<< HEAD
import { Controller, Post, Get, Body, Query, UseGuards, HttpCode, HttpStatus, Param, ParseUUIDPipe } from '@nestjs/common';
import { AdminVendorService } from '../services/admin-vendor.service.js';
import { CreateVendorDto } from '../dto/create-vendor.dto.js';
import { CompleteVendorDto } from '../dto/complete-vendor.dto.js';
=======
import { Controller, Post, Body, UseGuards, HttpCode, HttpStatus, Param, ParseUUIDPipe } from '@nestjs/common';
import { AdminVendorService } from '../services/admin-vendor.service.js';
import { CreateVendorDto } from '../dto/create-vendor.dto.js';
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
import { VendorStatusDto } from '../dto/vendor-status.dto.js';
import { JwtAuthGuard } from '../../auth/guards/jwt.guard.js';
import { RolesGuard } from '../../auth/guards/roles.guard.js';
import { Roles } from '../../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import type { JwtPayload } from '../../auth/services/jwt.service.js';
import { Role } from '@prisma/client';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminVendorController {
  constructor(private adminVendor: AdminVendorService) {}

<<<<<<< HEAD
  // GET /admin/vendors?status=all|active|pending|suspended
  @Get('vendors')
  @HttpCode(HttpStatus.OK)
  @Roles(Role.OPS_ADMIN, Role.SUPER_ADMIN)
  listVendors(@Query('status') status?: string) {
    return this.adminVendor.listVendors(status);
  }

=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  // EP-27
  @Post('vendors')
  @HttpCode(HttpStatus.CREATED)
  @Roles(Role.OPS_ADMIN, Role.SUPER_ADMIN)
  createVendor(@Body() dto: CreateVendorDto, @CurrentUser() user: JwtPayload) {
    return this.adminVendor.createVendor(dto, user.sub);
  }

<<<<<<< HEAD
  // POST /admin/vendors/:id/complete — complete a self-registered vendor
  @Post('vendors/:id/complete')
  @HttpCode(HttpStatus.OK)
  @Roles(Role.OPS_ADMIN, Role.SUPER_ADMIN)
  completeVendor(
    @Param('id', ParseUUIDPipe) vendorId: string,
    @Body() dto: CompleteVendorDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.adminVendor.completeVendorRegistration(vendorId, dto, user.sub);
  }

=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  // EP-28
  @Post('vendors/:id/suspend')
  @HttpCode(HttpStatus.OK)
  @Roles(Role.OPS_ADMIN, Role.SUPER_ADMIN)
  suspendVendor(
    @Param('id', ParseUUIDPipe) vendorId: string,
    @Body() dto: VendorStatusDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.adminVendor.suspendVendor(vendorId, dto.reason, user.sub);
  }

  // EP-29
  @Post('vendors/:id/reactivate')
  @HttpCode(HttpStatus.OK)
  @Roles(Role.OPS_ADMIN, Role.SUPER_ADMIN)
  reactivateVendor(
    @Param('id', ParseUUIDPipe) vendorId: string,
    @Body() dto: VendorStatusDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.adminVendor.reactivateVendor(vendorId, dto.reason, user.sub);
  }
}
