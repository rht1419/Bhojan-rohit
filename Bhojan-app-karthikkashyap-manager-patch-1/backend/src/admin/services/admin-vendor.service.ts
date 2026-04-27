import { Injectable, ConflictException, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { PrismaService } from '../../prisma/prisma.service.js';
import { RedisService } from '../../redis/redis.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import { OtpService } from '../../otp/services/otp.service.js';
import { CreateVendorDto } from '../dto/create-vendor.dto.js';
<<<<<<< HEAD
import { CompleteVendorDto } from '../dto/complete-vendor.dto.js';
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
import { AuditAction, AuditModule, Role, SuspensionAction } from '@prisma/client';

const ACTIVATION_TTL = 86400; // 24 hours

@Injectable()
export class AdminVendorService {
  private readonly logger = new Logger(AdminVendorService.name);

  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private audit: AuditService,
    private otp: OtpService,
  ) {}

<<<<<<< HEAD
  private buildActivationLink(activationToken: string): string {
    const frontendBase = (process.env.FRONTEND_URL ?? 'http://localhost:3000').replace(/\/$/, '');
    return `${frontendBase}/vendor/activate?activation_token=${activationToken}`;
  }

=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  // ── EP-27: Admin creates vendor ────────────────────────────────────────────

  async createVendor(dto: CreateVendorDto, adminId: string) {
    const existing = await this.prisma.user.findFirst({
      where: { OR: [{ phone: dto.phone }, { email: dto.email }] },
    });
    if (existing) {
      throw new ConflictException({ code: 'USER_ALREADY_EXISTS', message: 'Phone or email already registered.' });
    }

    const user = await this.prisma.user.create({
      data: {
        phone: dto.phone,
        email: dto.email,
        full_name: dto.full_name,
        role: Role.VENDOR,
        tenant_id: dto.tenant_id,
        is_active: false,
        is_verified: false,
        is_employee: false,
        vendor_profile: {
          create: {
            business_name: dto.business_name,
            business_address: dto.business_address,
            city: dto.city,
            state: dto.state,
            pincode: dto.pincode,
            gstin: dto.gstin ?? null,
          },
        },
      },
    });

    const activationToken = randomUUID();
    await this.redis.set(`activation:${activationToken}`, user.id, ACTIVATION_TTL);

<<<<<<< HEAD
    const activationLink = this.buildActivationLink(activationToken);
    this.logger.log(`[VENDOR-ACTIVATE] email=${dto.email} token=${activationToken}`);
    await this.otp.sendActivationEmail(dto.email, activationLink);
=======
    this.logger.log(`[VENDOR-ACTIVATE] email=${dto.email} token=${activationToken}`);
    await this.otp.sendActivationEmail(dto.email, `http://localhost:3000/vendor/auth/activate?activation_token=${activationToken}`);
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577

    await this.audit.log({
      userId: adminId,
      tenantId: dto.tenant_id,
      action: AuditAction.VENDOR_REGISTER,
      module: AuditModule.AUTH,
    });

    return { vendor_id: user.id, message: 'Vendor account created. Activation email sent.' };
  }

<<<<<<< HEAD
  // ── List vendors (all / active / pending) ─────────────────────────────────

  async listVendors(status?: string) {
    const whereBase = { role: Role.VENDOR };
    const where =
      status === 'pending'
        ? { ...whereBase, is_active: false, is_verified: false }
        : status === 'active'
        ? { ...whereBase, is_active: true, is_verified: true, is_suspended: false }
        : status === 'suspended'
        ? { ...whereBase, is_suspended: true }
        : whereBase;

    const users = await this.prisma.user.findMany({
      where,
      select: {
        id: true,
        phone: true,
        email: true,
        full_name: true,
        tenant_id: true,
        is_active: true,
        is_verified: true,
        is_suspended: true,
        created_at: true,
        vendor_profile: {
          select: {
            business_name: true,
            category: true,
            city: true,
            state: true,
          },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    return users.map((u) => ({
      ...u,
      status: u.is_suspended
        ? 'suspended'
        : u.is_active && u.is_verified
        ? 'active'
        : 'pending',
    }));
  }

  // ── Complete self-registered vendor (admin fills details + sends activation) ─

  async completeVendorRegistration(vendorId: string, dto: CompleteVendorDto, adminId: string) {
    const vendor = await this.prisma.user.findFirst({
      where: { id: vendorId, role: Role.VENDOR },
      include: { vendor_profile: true },
    });
    if (!vendor) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'Vendor not found.' });
    if (vendor.is_active && vendor.is_verified) {
      throw new BadRequestException({ code: 'VALIDATION_ERROR', message: 'Vendor is already activated.' });
    }

    await this.prisma.$transaction([
      this.prisma.vendorProfile.update({
        where: { user_id: vendorId },
        data: {
          business_address: dto.business_address,
          city: dto.city,
          state: dto.state,
          pincode: dto.pincode,
          ...(dto.gstin !== undefined && { gstin: dto.gstin }),
        },
      }),
      this.prisma.user.update({
        where: { id: vendorId },
        data: { tenant_id: dto.tenant_id },
      }),
    ]);

    const activationToken = randomUUID();
    await this.redis.set(`activation:${activationToken}`, vendorId, ACTIVATION_TTL);

    const email = vendor.email ?? '';
    const activationLink = this.buildActivationLink(activationToken);
    this.logger.log(`[VENDOR-COMPLETE] vendorId=${vendorId} token=${activationToken}`);
    await this.otp.sendActivationEmail(email, activationLink);

    await this.audit.log({
      userId: adminId,
      tenantId: dto.tenant_id,
      action: AuditAction.VENDOR_REGISTER,
      module: AuditModule.VENDOR,
      targetId: vendorId,
      metadata: { step: 'registration_completed' },
    });

    return { message: 'Vendor profile completed. Activation email sent.' };
  }

=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  // ── EP-28: Suspend vendor ───────────────────────────────────────────────────
  async suspendVendor(vendorId: string, reason: string, adminId: string) {
    const vendor = await this.prisma.user.findFirst({
      where: { id: vendorId, role: Role.VENDOR },
      select: { id: true, is_suspended: true, tenant_id: true, email: true, full_name: true },
    });
    if (!vendor) throw new NotFoundException('Vendor not found.');
    if (vendor.is_suspended) throw new BadRequestException('Vendor already suspended.');

    await this.prisma.user.update({ where: { id: vendor.id }, data: { is_suspended: true, suspend_reason: reason } });

    const activeSessions = await this.prisma.session.findMany({
      where: { user_id: vendor.id, is_revoked: false },
      select: { id: true, refresh_token: true, expires_at: true },
    });
    await this.prisma.session.updateMany({
      where: { user_id: vendor.id, is_revoked: false },
      data: { is_revoked: true },
    });
    for (const session of activeSessions) {
      const ttl = Math.max(0, Math.floor((session.expires_at.getTime() - Date.now()) / 1000));
      if (ttl > 0) await this.redis.set(`blacklist:${session.refresh_token}`, '1', ttl);
    }

    await this.prisma.vendorSuspensionLog.create({
      data: {
        vendor_id: vendor.id,
        action: SuspensionAction.SUSPENDED,
        reason,
        actioned_by: adminId,
      },
    });

    await this.audit.log({
      userId: adminId,
      tenantId: vendor.tenant_id ?? undefined,
      action: AuditAction.VENDOR_SUSPENDED,
      module: AuditModule.VENDOR,
      targetId: vendor.id,
      metadata: { reason, email: vendor.email, full_name: vendor.full_name },
    });

    return { message: 'Vendor suspended successfully.' };
  }

  // ── EP-29: Reactivate vendor ────────────────────────────────────────────────
  async reactivateVendor(vendorId: string, reason: string, adminId: string) {
    const vendor = await this.prisma.user.findFirst({
      where: { id: vendorId, role: Role.VENDOR },
      select: { id: true, is_suspended: true, tenant_id: true, email: true, full_name: true },
    });
    if (!vendor) throw new NotFoundException('Vendor not found.');
    if (!vendor.is_suspended) throw new BadRequestException('Vendor is not suspended.');

    await this.prisma.user.update({ where: { id: vendor.id }, data: { is_suspended: false, suspend_reason: null } });

    await this.prisma.vendorSuspensionLog.create({
      data: {
        vendor_id: vendor.id,
        action: SuspensionAction.REACTIVATED,
        reason,
        actioned_by: adminId,
      },
    });

    await this.audit.log({
      userId: adminId,
      tenantId: vendor.tenant_id ?? undefined,
      action: AuditAction.VENDOR_REACTIVATED,
      module: AuditModule.VENDOR,
      targetId: vendor.id,
      metadata: { reason, email: vendor.email, full_name: vendor.full_name },
    });

    return { message: 'Vendor reactivated successfully.' };
  }
}
