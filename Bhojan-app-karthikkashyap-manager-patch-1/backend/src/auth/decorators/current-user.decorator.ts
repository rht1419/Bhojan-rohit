import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { JwtPayload } from '../services/jwt.service.js';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): JwtPayload => {
    return ctx.switchToHttp().getRequest<{ user: JwtPayload }>().user;
  },
);
