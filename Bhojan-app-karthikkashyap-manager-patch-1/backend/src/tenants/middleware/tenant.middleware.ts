import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';

export interface RequestWithTenant extends Request {
  tenantId?: string | null;
  userId?: string;
  userRole?: string;
}

@Injectable()
export class TenantMiddleware implements NestMiddleware {
  constructor(private jwt: JwtService, private config: ConfigService) {}

  use(req: RequestWithTenant, _res: Response, next: NextFunction) {
    const auth = req.headers['authorization'];
    if (auth?.startsWith('Bearer ')) {
      try {
        const token = auth.slice(7);
        const payload = this.jwt.verify<{ sub: string; tenant_id: string | null; role: string }>(
          token,
          { secret: this.config.get('JWT_SECRET') },
        );
        req.tenantId = payload.tenant_id;
        req.userId   = payload.sub;
        req.userRole = payload.role;
      } catch {
        // Non-blocking — guard will reject if auth is required
      }
    }
    next();
  }
}
