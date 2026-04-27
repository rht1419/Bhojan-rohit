import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
<<<<<<< HEAD
  constructor() {
    const dbUrl = process.env.DATABASE_URL;
    if (!dbUrl) {
      throw new Error(
        'Missing DATABASE_URL. Copy backend/.env.example to backend/.env and set DATABASE_URL.',
      );
    }

    super({
      datasourceUrl: dbUrl,
    });
  }

=======
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
  async onModuleInit() {
    await this.$connect();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
