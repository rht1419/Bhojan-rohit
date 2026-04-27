import { Injectable, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  handleRequest<T>(err: Error, user: T, info: { message?: string }): T {
    if (err || !user) {
      throw new UnauthorizedException({
        code: info?.message === 'jwt expired' ? 'TOKEN_EXPIRED' : 'UNAUTHORIZED',
        message: info?.message === 'jwt expired' ? 'Access token expired.' : 'Authentication required.',
      });
    }
    return user;
  }
}
