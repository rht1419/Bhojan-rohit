import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AppModule, AuditAction, AuditModule, Prisma, Role } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import type { CreateDelegationDto, DelegationQueryDto } from '../dto/create-delegation.dto.js';

@Injectable()
export class AdminDelegationService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private audit: AuditService,
  ) {}

  async createDelegation(delegatorId: string, dto: CreateDelegationDto) {
    const delegatee = await this.prisma.user.findFirst({
      where: { id: dto.delegatee_id, role: { in: [Role.OPS_ADMIN, Role.TECH_ADMIN] }, is_active: true },
      select: { id: true, tenant_id: true },
    });
    if (!delegatee) throw new NotFoundException('Delegatee not found or inactive.');

    const startsAt = dto.starts_at ? new Date(dto.starts_at) : new Date();
    const expiresAt = new Date(dto.expires_at);
    if (expiresAt <= startsAt) throw new BadRequestException('expires_at must be after starts_at.');

    const delegation = await this.prisma.delegation.create({
      data: {
        delegator_id: delegatorId,
        delegatee_id: dto.delegatee_id,
        module: dto.module,
        reason: dto.reason ?? null,
        starts_at: startsAt,
        expires_at: expiresAt,
      },
      select: { id: true, delegatee_id: true, module: true, expires_at: true },
    });

    const ttl = Math.max(1, Math.floor((delegation.expires_at.getTime() - Date.now()) / 1000));
    await this.redis.set(`delegate:${delegation.delegatee_id}:${delegation.module}`, '1', ttl);

    await this.audit.log({
      userId: delegatorId,
      tenantId: delegatee.tenant_id ?? undefined,
      action: AuditAction.DELEGATE_GRANTED,
      module: AuditModule.DELEGATION,
      targetId: delegation.delegatee_id,
      metadata: { delegation_id: delegation.id, delegated_module: delegation.module },
    });

    return {
      delegation_id: delegation.id,
      delegatee_id: delegation.delegatee_id,
      module: delegation.module,
      expires_at: delegation.expires_at,
      message: 'Delegation created successfully.',
    };
  }

  async listDelegations(callerRole: Role, callerTenantId: string | null, query: DelegationQueryDto) {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;
    const now = new Date();

    const where: Prisma.DelegationWhereInput = {
      is_active: true,
      expires_at: { gt: now },
    };

    if (query.delegatee_id) where.delegatee_id = query.delegatee_id;
    if (query.module) where.module = query.module;
    if (callerRole === Role.OPS_ADMIN) {
      where.delegatee = { tenant_id: callerTenantId ?? undefined };
    }

    const [total, rows] = await Promise.all([
      this.prisma.delegation.count({ where }),
      this.prisma.delegation.findMany({
        where,
        skip,
        take: limit,
        orderBy: { expires_at: 'asc' },
        select: {
          id: true,
          delegator_id: true,
          delegatee_id: true,
          module: true,
          reason: true,
          starts_at: true,
          expires_at: true,
          delegatee: { select: { full_name: true, email: true } },
        },
      }),
    ]);

    return {
      delegations: rows.map((row) => ({
        id: row.id,
        delegator_id: row.delegator_id,
        delegatee_id: row.delegatee_id,
        delegatee_name: row.delegatee.full_name,
        delegatee_email: row.delegatee.email,
        module: row.module,
        reason: row.reason,
        starts_at: row.starts_at,
        expires_at: row.expires_at,
      })),
      pagination: { page, limit, total, total_pages: Math.ceil(total / limit) },
    };
  }

  async revokeDelegation(delegationId: string, revokedBy: string) {
    const delegation = await this.prisma.delegation.findUnique({
      where: { id: delegationId },
      select: { id: true, delegatee_id: true, module: true, is_active: true },
    });
    if (!delegation || !delegation.is_active) throw new NotFoundException('Active delegation not found.');

    await this.prisma.delegation.update({ where: { id: delegation.id }, data: { is_active: false } });
    await this.redis.del(`delegate:${delegation.delegatee_id}:${delegation.module}`);

    await this.audit.log({
      userId: revokedBy,
      action: AuditAction.DELEGATE_REVOKED,
      module: AuditModule.DELEGATION,
      targetId: delegation.delegatee_id,
      metadata: { delegation_id: delegation.id, delegated_module: delegation.module },
    });

    return { message: 'Delegation revoked successfully.' };
  }

  @Cron(CronExpression.EVERY_5_MINUTES)
  async revokeExpiredDelegations() {
    const now = new Date();
    const expired = await this.prisma.delegation.findMany({
      where: { is_active: true, expires_at: { lte: now } },
      select: { id: true, delegatee_id: true, module: true, delegator_id: true },
    });
    if (!expired.length) return;

    await this.prisma.delegation.updateMany({
      where: { id: { in: expired.map((x) => x.id) } },
      data: { is_active: false },
    });

    for (const item of expired) {
      await this.redis.del(`delegate:${item.delegatee_id}:${item.module}`);
      await this.audit.log({
        userId: item.delegator_id,
        action: AuditAction.DELEGATE_REVOKED,
        module: AuditModule.DELEGATION,
        targetId: item.delegatee_id,
        metadata: { delegation_id: item.id, reason: 'AUTO_EXPIRED' },
      });
    }
  }
}

