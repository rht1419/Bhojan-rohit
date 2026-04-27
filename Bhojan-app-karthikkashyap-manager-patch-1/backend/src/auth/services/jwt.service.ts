import { Injectable } from '@nestjs/common';
import { JwtService as NestJwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { RedisService } from '../../redis/redis.service.js';

export interface JwtPayload {
  sub: string;
  role: string;
  tenant_id: string | null;
  is_employee: boolean;
}

@Injectable()
export class TokenService {
  constructor(
    private jwt: NestJwtService,
    private config: ConfigService,
    private redis: RedisService,
  ) {}

  issueAccessToken(payload: JwtPayload): string {
    return this.jwt.sign(payload, {
      secret: this.config.getOrThrow('JWT_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRES_IN', '15m'),
    });
  }

  issueRefreshToken(payload: JwtPayload): string {
    return this.jwt.sign(payload, {
      secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
      expiresIn: this.config.get('JWT_REFRESH_EXPIRES_IN', '7d'),
    });
  }

  verifyAccessToken(token: string): JwtPayload {
    return this.jwt.verify<JwtPayload>(token, {
      secret: this.config.getOrThrow('JWT_SECRET'),
    });
  }

  verifyRefreshToken(token: string): JwtPayload {
    return this.jwt.verify<JwtPayload>(token, {
      secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
    });
  }

  async blacklistToken(token: string, ttlSeconds: number): Promise<void> {
    await this.redis.set(`blacklist:${token}`, '1', ttlSeconds);
  }

  async isBlacklisted(token: string): Promise<boolean> {
    return this.redis.exists(`blacklist:${token}`);
  }
}
