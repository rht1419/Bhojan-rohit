import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module.js';
import { globalValidationPipe } from './common/pipes/validation.pipe.js';
import { HttpExceptionFilter } from './common/filters/http-exception.filter.js';
import { ResponseInterceptor } from './common/interceptors/response.interceptor.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

<<<<<<< HEAD
  // #region agent log H10 request ingress
  app.use((req, _res, next) => {
    console.log(`[DBG-H10] ingress method=${req.method} url=${req.url} origin=${req.headers.origin ?? 'NA'}`);
    next();
  });
  // #endregion

=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  app.useGlobalPipes(globalValidationPipe);
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new ResponseInterceptor());

  app.enableCors({ origin: '*' });

  const port = process.env['PORT'] ?? 3000;
  await app.listen(port);
  console.log(`Bhojan backend running on http://localhost:${port}`);
}

bootstrap();
