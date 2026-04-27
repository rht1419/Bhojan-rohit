import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service.js';

@Injectable()
export class TenantsService {
  constructor(private prisma: PrismaService) {}

  // EP-35 — GET /tenants
  async findAllActive() {
    const tenants = await this.prisma.tenant.findMany({
      where: { is_active: true },
      select: {
        id: true,
        name: true,
        logo_url: true,
        settings: {
          select: {
            meal_window_start: true,
            meal_window_end: true,
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    return tenants.map((t) => ({
      id: t.id,
      name: t.name,
      logo_url: t.logo_url,
      has_active_cafeteria: !!(t.settings?.meal_window_start && t.settings?.meal_window_end),
    }));
  }

  // EP-36 — GET /tenants/:id/settings
  async getSettings(tenantId: string) {
    const tenant = await this.prisma.tenant.findFirst({
      where: { id: tenantId, is_active: true },
      include: { settings: true },
    });

    if (!tenant) {
      throw new NotFoundException({ code: 'TENANT_NOT_FOUND', message: 'Tenant not found.' });
    }

    const s = tenant.settings;
    return {
      tenant_id: tenant.id,
      subsidy_per_meal: s?.subsidy_per_meal ?? null,
      meal_window_start: s?.meal_window_start ?? null,
      meal_window_end: s?.meal_window_end ?? null,
      wallet_enabled: s?.wallet_enabled ?? false,
      max_wallet_balance: s?.max_wallet_balance ?? null,
    };
  }

  // EP-37 — POST /tenants/validate
  async validate(tenantId: string) {
    const tenant = await this.prisma.tenant.findFirst({
      where: { id: tenantId },
      include: { settings: true },
    });

    if (!tenant || !tenant.is_active) {
      throw new ForbiddenException({ code: 'TENANT_CLOSED', message: 'Registrations paused for this location.' });
    }

    return { is_open: true, message: 'Tenant accepting registrations' };
  }
}
