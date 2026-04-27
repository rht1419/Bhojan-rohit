import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../../prisma/prisma.service.js';
import { AuditService } from '../../audit/services/audit.service.js';
import type { UpdateProfileDto } from '../dto/update-profile.dto.js';
import { AuditAction, AuditModule, Prisma } from '@prisma/client';

@Injectable()
export class ProfileService {
  private readonly logger = new Logger(ProfileService.name);

  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private config: ConfigService,
  ) {}

  // ── EP-07: Update Profile ──────────────────────────────────────────────────

  async updateProfile(userId: string, dto: UpdateProfileDto) {
    const [profile] = await Promise.all([
      this.prisma.userProfile.upsert({
        where: { user_id: userId },
        update: {
          ...(dto.full_name !== undefined && { full_name: dto.full_name }),
          ...(dto.department !== undefined && { department: dto.department }),
          ...(dto.floor !== undefined && { floor: dto.floor }),
          ...(dto.building !== undefined && { building: dto.building }),
          ...(dto.preferences !== undefined && { preferences: dto.preferences as Prisma.InputJsonValue }),
        },
        create: {
          user_id: userId,
          full_name: dto.full_name ?? '',
          department: dto.department,
          floor: dto.floor,
          building: dto.building,
          ...(dto.preferences !== undefined && { preferences: dto.preferences as Prisma.InputJsonValue }),
        },
        select: {
          full_name: true, avatar_url: true, department: true,
          floor: true, building: true, preferences: true,
        },
      }),
      dto.full_name
        ? this.prisma.user.update({ where: { id: userId }, data: { full_name: dto.full_name } })
        : Promise.resolve(),
    ]);

    await this.audit.log({ userId, action: AuditAction.PROFILE_UPDATED, module: AuditModule.AUTH });

    return { profile };
  }

  // ── EP-08: Avatar Upload (Supabase Storage) ────────────────────────────────

  async uploadAvatar(file: Express.Multer.File, userId: string) {
    const supabaseUrl = this.config.getOrThrow<string>('SUPABASE_URL');
    const serviceKey = this.config.getOrThrow<string>('SUPABASE_SERVICE_ROLE_KEY');

    const ext = file.mimetype === 'image/png' ? 'png' : 'jpg';
    const path = `${userId}.${ext}`;

    const uploadUrl = `${supabaseUrl}/storage/v1/object/avatars/${path}`;
    const response = await fetch(uploadUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${serviceKey}`,
        'Content-Type': file.mimetype,
        'x-upsert': 'true',
      },
      body: new Uint8Array(file.buffer),
    });

    if (!response.ok) {
      const body = await response.text();
      this.logger.error(`Supabase Storage upload failed: ${response.status} ${body}`);
      throw new BadRequestException({ code: 'UPLOAD_FAILED', message: 'Avatar upload failed.' });
    }

    const avatarUrl = `${supabaseUrl}/storage/v1/object/public/avatars/${path}`;

    await this.prisma.userProfile.upsert({
      where: { user_id: userId },
      update: { avatar_url: avatarUrl },
      create: { user_id: userId, full_name: '', avatar_url: avatarUrl },
    });

    await this.audit.log({ userId, action: AuditAction.PROFILE_UPDATED, module: AuditModule.AUTH, metadata: { field: 'avatar_url' } });

    return { avatar_url: avatarUrl };
  }
}
