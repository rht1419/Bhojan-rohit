import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Param,
  Query,
  Req,
  ParseUUIDPipe,
  UseGuards,
  HttpCode,
  HttpStatus,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import type { Request } from 'express';
import { AdminEmployeeService } from '../services/admin-employee.service.js';
import { AuditLogQueryDto } from '../dto/audit-log-query.dto.js';
import { AuditExportQueryDto } from '../dto/audit-export-query.dto.js';
import { BulkUploadDto } from '../dto/bulk-upload.dto.js';
import { OffboardEmployeeDto } from '../dto/offboard-employee.dto.js';
import { SessionsQueryDto } from '../dto/sessions-query.dto.js';
import { JwtAuthGuard } from '../../auth/guards/jwt.guard.js';
import { RolesGuard } from '../../auth/guards/roles.guard.js';
import { Roles } from '../../auth/decorators/roles.decorator.js';
import { CurrentUser } from '../../auth/decorators/current-user.decorator.js';
import type { JwtPayload } from '../../auth/services/jwt.service.js';
import { Role } from '@prisma/client';

@Controller('admin')
@UseGuards(JwtAuthGuard, RolesGuard)
export class AdminEmployeeController {
  constructor(private adminEmployee: AdminEmployeeService) {}

  // ── EP-22 — GET /admin/audit-logs ─────────────────────────────────────────
  @Get('audit-logs')
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN, Role.TECH_ADMIN)
  getAuditLogs(@CurrentUser() user: JwtPayload, @Query() query: AuditLogQueryDto) {
    return this.adminEmployee.getAuditLogs(user.role as Role, user.tenant_id, query);
  }

  // ── EP-23 — GET /admin/audit-logs/export (async CSV export) ──────────────
  // NOTE: This route MUST be declared before the `:id` parameterised routes
  // to prevent NestJS from treating "export" as a UUID param.
  @Get('audit-logs/export')
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN, Role.TECH_ADMIN)
  exportAuditLogs(@CurrentUser() user: JwtPayload, @Query() query: AuditExportQueryDto) {
    return this.adminEmployee.exportAuditLogs(user.role as Role, user.tenant_id, query);
  }

  // ── EP-24 — POST /admin/employees/bulk-upload ─────────────────────────────
  @Post('employees/bulk-upload')
  @HttpCode(HttpStatus.ACCEPTED)
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
    }),
  )
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN)
  uploadEmployeesCsv(
    @CurrentUser() user: JwtPayload,
    @Body() dto: BulkUploadDto,
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.adminEmployee.uploadEmployeesCsv(
      user.role as Role,
      user.tenant_id,
      user.sub,
      dto,
      file,
    );
  }

  // ── EP-25 — GET /admin/employees/bulk-upload/:id ──────────────────────────
  @Get('employees/bulk-upload/:id')
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN)
  getBulkUploadStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.adminEmployee.getBulkUploadStatus(id, user.role as Role, user.tenant_id);
  }

  // ── EP-26 — POST /admin/employees/:id/offboard ────────────────────────────
  @Post('employees/:id/offboard')
  @HttpCode(HttpStatus.OK)
  @Roles(Role.SUPER_ADMIN, Role.OPS_ADMIN)
  offboardEmployee(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: OffboardEmployeeDto,
    @CurrentUser() user: JwtPayload,
    @Req() req: Request,
  ) {
    return this.adminEmployee.offboardEmployee(id, dto, user.sub, user.role as Role, user.tenant_id, req.ip);
  }

  // ── EP-33 — GET /admin/sessions ───────────────────────────────────────────
  @Get('sessions')
  @Roles(Role.SUPER_ADMIN, Role.TECH_ADMIN)
  getSessions(@Query() query: SessionsQueryDto) {
    return this.adminEmployee.getSessions(query);
  }

  // ── EP-34 — DELETE /admin/sessions/:id ───────────────────────────────────
  @Delete('sessions/:id')
  @Roles(Role.SUPER_ADMIN, Role.TECH_ADMIN)
  revokeSession(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.adminEmployee.revokeSession(id, user.sub);
  }
}
