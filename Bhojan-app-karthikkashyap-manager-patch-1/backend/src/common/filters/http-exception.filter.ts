import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let code = 'INTERNAL_ERROR';
    let message = 'An unexpected error occurred';
    let details: unknown[] | undefined;

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const body = exception.getResponse();

      if (typeof body === 'object' && body !== null) {
        const b = body as Record<string, unknown>;
        code    = (b['code'] as string)    ?? this.statusToCode(status);
        message = (b['message'] as string) ?? exception.message;
        details = b['details'] as unknown[] | undefined;
      } else {
        code    = this.statusToCode(status);
        message = typeof body === 'string' ? body : exception.message;
      }
<<<<<<< HEAD

      this.logger.warn(
        `[DBG-H6] http-exception method=${request.method} url=${request.url} status=${status} code=${code} messageType=${Array.isArray(message) ? 'array' : typeof message} detailsCount=${details?.length ?? 0}`,
      );
=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
    } else {
      this.logger.error(`Unhandled exception on ${request.method} ${request.url}`, exception);
    }

    response.status(status).json({
      success: false,
      error: { code, message, ...(details?.length && { details }) },
    });
  }

  private statusToCode(status: number): string {
    const map: Record<number, string> = {
      400: 'VALIDATION_ERROR',
      401: 'UNAUTHORIZED',
      403: 'PERMISSION_DENIED',
      404: 'USER_NOT_FOUND',
      409: 'CONFLICT',
      429: 'RATE_LIMIT_EXCEEDED',
      500: 'INTERNAL_ERROR',
    };
    return map[status] ?? 'INTERNAL_ERROR';
  }
}
