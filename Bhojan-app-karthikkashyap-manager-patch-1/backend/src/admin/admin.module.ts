import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bull';
import { AdminAuthController } from './controllers/admin-auth.controller.js';
import { AdminVendorController } from './controllers/admin-vendor.controller.js';
import { AdminEmployeeController } from './controllers/admin-employee.controller.js';
import { AdminDelegationController } from './controllers/admin-delegation.controller.js';
import { AdminAuthService } from './services/admin-auth.service.js';
import { AdminVendorService } from './services/admin-vendor.service.js';
import { AdminEmployeeService } from './services/admin-employee.service.js';
import { AdminDelegationService } from './services/admin-delegation.service.js';
import { EmployeeBulkUploadProcessor } from './processors/employee-bulk-upload.processor.js';
import { AuditExportProcessor } from './processors/audit-export.processor.js';
import { AuthModule } from '../auth/auth.module.js';
import { AuditModule } from '../audit/audit.module.js';
import { OtpModule } from '../otp/otp.module.js';

@Module({
  imports: [
    AuthModule,
    AuditModule,
    OtpModule,
    // Register Bull queues used by AdminEmployeeService
    BullModule.registerQueue(
      { name: 'employee-bulk-upload' },
      { name: 'audit-export' },
    ),
  ],
  controllers: [
    AdminAuthController,
    AdminVendorController,
    AdminEmployeeController,
    AdminDelegationController,
  ],
  providers: [
    AdminAuthService,
    AdminVendorService,
    AdminEmployeeService,
    AdminDelegationService,
    EmployeeBulkUploadProcessor,
    AuditExportProcessor,
  ],
})
export class AdminModule {}
