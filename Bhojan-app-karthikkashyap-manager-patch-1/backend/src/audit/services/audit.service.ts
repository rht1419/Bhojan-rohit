import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AuditAction, AuditModule, Prisma } from '@prisma/client';

interface LogParams {
  userId?: string;
  tenantId?: string;
  action: AuditAction;
  module: AuditModule;
  targetId?: string;
  ipAddress?: string;
  device?: string;
  metadata?: Prisma.InputJsonValue;
}

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);

  constructor(private prisma: PrismaService) {}

  async log(params: LogParams): Promise<void> {
    try {
      await this.prisma.auditLog.create({
        data: {
          action: params.action,
          module: params.module,
          user_id: params.userId ?? null,
          tenant_id: params.tenantId ?? null,
          target_id: params.targetId ?? null,
          ip_address: params.ipAddress ?? null,
          device: params.device ?? null,
          metadata: params.metadata ?? Prisma.JsonNull,
        },
      });
    } catch (err) {
      // Audit failures must never break the main request
      this.logger.error('Failed to write audit log', err);
    }
  }
}
