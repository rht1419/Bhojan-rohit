<<<<<<< HEAD
# Bhojan Backend

NestJS REST API for the Bhojan corporate food ordering platform.

## Setup

```bash
npm install
cp .env.example .env   # see Environment Variables below
npx prisma db push
npm run start:dev
```

Server runs on **http://localhost:3000**.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Supabase PostgreSQL connection string |
| `REDIS_URL` | Upstash Redis URL |
| `JWT_ACCESS_SECRET` | Secret for 15-minute access tokens |
| `JWT_REFRESH_SECRET` | Secret for 7-day refresh tokens |
| `FAST2SMS_API_KEY` | Fast2SMS key for phone OTPs |
| `SENDGRID_API_KEY` | SendGrid key for activation emails |
| `SENDGRID_FROM_EMAIL` | Verified sender address |
| `FRONTEND_URL` | Flutter deep-link base (for email links) |
| `PORT` | HTTP port (default 3000) |

## Scripts

```bash
npm run start:dev     # watch mode
npm run start:prod    # production
npm run test          # unit tests
npm run test:e2e      # end-to-end tests
npm run test:cov      # coverage report
npx prisma studio     # DB GUI
```

## API Modules

| Module | Routes | Notes |
|--------|--------|-------|
| User Auth | `POST /auth/*` | EP-01–16, JWT + OTP |
| Vendor Auth | `POST /vendor/auth/*` | EP-17–19 + self-reg |
| Admin Auth | `POST /admin/auth/*` | EP-20–21, role-based |
| Admin Vendors | `GET/POST /admin/vendors/*` | EP-27–29 + complete-reg |
| Admin Employees | `POST /admin/employees/*` | EP-24, 26 |
| Admin Delegation | `GET/POST /admin/delegations/*` | EP-30–32 |
| Admin Sessions | `GET /admin/sessions/*` | EP-33–34 |
| Audit Logs | `GET /admin/audit-logs` | EP-22–23 |
| Tenants | `GET /tenants/*` | EP-35–37 |

## Vendor Self-Registration Endpoints (no auth required)

```
POST /vendor/auth/register     { business_name, email, phone, category }
POST /vendor/auth/request-otp  { phone }
POST /vendor/auth/verify-otp   { phone, otp }  → returns access_token + refresh_token
```

## Key Files

```
src/
├── vendor/
│   ├── controllers/vendor.controller.ts
│   ├── services/vendor.service.ts
│   └── dto/
├── admin/
│   ├── controllers/admin-vendor.controller.ts
│   ├── services/admin-vendor.service.ts
│   └── dto/
├── auth/services/jwt.service.ts
├── otp/services/otp.service.ts
└── prisma/schema.prisma
```

## Database

PostgreSQL managed on Supabase. Schema managed with Prisma.

To apply schema changes:
```bash
npx prisma db push          # non-interactive (CI / dev)
npx prisma migrate dev      # interactive with migration file
npx prisma generate         # regenerate client after schema edits
```
=======
<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

[Nest](https://github.com/nestjs/nest) framework TypeScript starter repository.

## Project setup

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
>>>>>>> 9164b54b7ae96a96dfb046b32a6f1d92bc55e577
