import { Controller, Delete, Get, Param, ParseUUIDPipe, Post, Query, Body, UseGuards, HttpCode, HttpStatus } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../../auth/guards/jwt.guard.js';
import { RolesGuard } from '../../auth/guards/roles.guard.js';
import { Roles } from '../../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import type { JwtPayload } from '../../auth/services/jwt.service.js';
import { AdminDelegationService } from '../services/admin-delegation.service.js';
import { CreateDelegationDto, DelegationQueryDto } from '../dto/create-delegation.dto.js';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminDelegationController {
  constructor(private readonly delegationService: AdminDelegationService) {}

  // EP-30
  @Post('delegations')
  @HttpCode(HttpStatus.CREATED)
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN)
  createDelegation(@CurrentUser() user: JwtPayload, @Body() dto: CreateDelegationDto) {
    return this.delegationService.createDelegation(user.sub, dto);
  }

  // EP-31
  @Get('delegations')
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN, Role.TECH_ADMIN)
  listDelegations(@CurrentUser() user: JwtPayload, @Query() query: DelegationQueryDto) {
    return this.delegationService.listDelegations(user.role as Role, user.tenant_id, query);
  }

  // EP-32
  @Delete('delegations/:id')
  @HttpCode(HttpStatus.OK)
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN)
  revokeDelegation(@CurrentUser() user: JwtPayload, @Param('id', ParseUUIDPipe) delegationId: string) {
    return this.delegationService.revokeDelegation(delegationId, user.sub);
  }
}

