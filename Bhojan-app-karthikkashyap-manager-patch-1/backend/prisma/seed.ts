 
import {
  AppModule,
  AuditAction,
  AuditModule,
  ContactStatus,
  ContactType,
  Prisma,
  PrismaClient,
  Role,
  UploadStatus,
  UpgradeStatus,
} from '@prisma/client';
import bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const PASSWORD_PLAIN = 'Test@1234';
const PASSWORD_SALT_ROUNDS = 12;

type SeedUser = {
  full_name: string;
  phone: string;
  email: string | null;
  role: Role;
  tenant_id: string | null;
  employee_id: string | null;
  is_employee: boolean;
  is_verified: boolean;
  is_active: boolean;
  is_suspended?: boolean;
};

function buildPermissions(role: Role, module: AppModule) {
  if (role === Role.SUPER_ADMIN) {
    return { can_create: true, can_read: true, can_update: true, can_delete: true };
  }

  if (role === Role.TECH_ADMIN) {
    const techModules = new Set<AppModule>([
      AppModule.SETTINGS,
      AppModule.TENANT,
      AppModule.SESSION,
      AppModule.REPORT,
      AppModule.AUTH,
    ]);
    const allowed = techModules.has(module);
    return { can_create: allowed, can_read: allowed, can_update: allowed, can_delete: allowed };
  }

  if (role === Role.OPS_ADMIN) {
    const opsModules = new Set<AppModule>([
      AppModule.AUTH,
      AppModule.VENDOR,
      AppModule.EMPLOYEE,
      AppModule.ORDER,
      AppModule.REPORT,
      AppModule.DELEGATION,
      AppModule.SESSION,
    ]);
    const allowed = opsModules.has(module);
    return {
      can_create: allowed,
      can_read: allowed,
      can_update: allowed,
      can_delete: module === AppModule.VENDOR || module === AppModule.EMPLOYEE || module === AppModule.SESSION,
    };
  }

  if (role === Role.VENDOR) {
    return {
      can_create: module === AppModule.MENU,
      can_read: module === AppModule.MENU || module === AppModule.ORDER || module === AppModule.REPORT,
      can_update: module === AppModule.MENU || module === AppModule.ORDER,
      can_delete: module === AppModule.MENU,
    };
  }

  if (role === Role.USER || role === Role.GUEST) {
    return {
      can_create: module === AppModule.ORDER,
      can_read: module === AppModule.AUTH || module === AppModule.ORDER,
      can_update: module === AppModule.AUTH || module === AppModule.ORDER,
      can_delete: false,
    };
  }

  return { can_create: false, can_read: false, can_update: false, can_delete: false };
}

async function main() {
  const password_hash = await bcrypt.hash(PASSWORD_PLAIN, PASSWORD_SALT_ROUNDS);

  const infosys = await prisma.tenant.upsert({
    where: { domain: 'infosys.com' },
    update: { name: 'Infosys Bangalore', schema_name: 'infosys_bangalore', is_active: true },
    create: {
      name: 'Infosys Bangalore',
      domain: 'infosys.com',
      schema_name: 'infosys_bangalore',
      logo_url: 'https://cdn.bhojan.app/tenants/infosys.png',
      is_active: true,
    },
  });

  const wipro = await prisma.tenant.upsert({
    where: { domain: 'wipro.com' },
    update: { name: 'Wipro Whitefield', schema_name: 'wipro_whitefield', is_active: true },
    create: {
      name: 'Wipro Whitefield',
      domain: 'wipro.com',
      schema_name: 'wipro_whitefield',
      logo_url: 'https://cdn.bhojan.app/tenants/wipro.png',
      is_active: true,
    },
  });

  const capgemini = await prisma.tenant.upsert({
    where: { domain: 'capgemini.com' },
    update: { name: 'Capgemini', schema_name: 'capgemini_manyata', is_active: true },
    create: {
      name: 'Capgemini',
      domain: 'capgemini.com',
      schema_name: 'capgemini_manyata',
      logo_url: 'https://cdn.bhojan.app/tenants/capgemini.png',
      is_active: true,
    },
  });

  await prisma.tenantSettings.upsert({
    where: { tenant_id: infosys.id },
    update: {},
    create: {
      tenant_id: infosys.id,
      subsidy_per_meal: new Prisma.Decimal('80.00'),
      subsidy_per_day_limit: new Prisma.Decimal('160.00'),
      subsidy_reset_cycle: 'DAILY',
      meal_window_start: '07:00',
      meal_window_end: '22:00',
      wallet_enabled: true,
      max_wallet_balance: new Prisma.Decimal('3000.00'),
      config: { campus: 'Electronic City' },
    },
  });

  await prisma.tenantSettings.upsert({
    where: { tenant_id: wipro.id },
    update: {},
    create: {
      tenant_id: wipro.id,
      subsidy_per_meal: new Prisma.Decimal('70.00'),
      subsidy_per_day_limit: new Prisma.Decimal('140.00'),
      subsidy_reset_cycle: 'DAILY',
      meal_window_start: '07:30',
      meal_window_end: '21:30',
      wallet_enabled: true,
      max_wallet_balance: new Prisma.Decimal('2500.00'),
      config: { campus: 'Whitefield' },
    },
  });

  await prisma.tenantSettings.upsert({
    where: { tenant_id: capgemini.id },
    update: {},
    create: {
      tenant_id: capgemini.id,
      subsidy_per_meal: new Prisma.Decimal('60.00'),
      subsidy_per_day_limit: new Prisma.Decimal('120.00'),
      subsidy_reset_cycle: 'DAILY',
      meal_window_start: '08:00',
      meal_window_end: '21:00',
      wallet_enabled: false,
      max_wallet_balance: new Prisma.Decimal('0.00'),
      config: { campus: 'Manyata Tech Park' },
    },
  });

  const seedUsers: SeedUser[] = [
    {
      full_name: 'Platform Super Admin',
      phone: '+919999900001',
      email: 'super@bhojan.app',
      role: Role.SUPER_ADMIN,
      tenant_id: infosys.id,
      employee_id: 'INF-ADMIN-001',
      is_employee: false,
      is_verified: true,
      is_active: true,
    },
    {
      full_name: 'Operations Admin',
      phone: '+919999900002',
      email: 'ops@bhojan.app',
      role: Role.OPS_ADMIN,
      tenant_id: infosys.id,
      employee_id: 'INF-ADMIN-002',
      is_employee: false,
      is_verified: true,
      is_active: true,
    },
    {
      full_name: 'Technology Admin',
      phone: '+919999900003',
      email: 'tech@bhojan.app',
      role: Role.TECH_ADMIN,
      tenant_id: infosys.id,
      employee_id: 'INF-ADMIN-003',
      is_employee: false,
      is_verified: true,
      is_active: true,
    },
    {
      full_name: 'Infosys Employee 001',
      phone: '+919999900004',
      email: 'emp001@infosys.com',
      role: Role.USER,
      tenant_id: infosys.id,
      employee_id: 'INF-EMP-001',
      is_employee: true,
      is_verified: true,
      is_active: true,
    },
    {
      full_name: 'Wipro Employee 001',
      phone: '+919999900007',
      email: 'emp001@wipro.com',
      role: Role.USER,
      tenant_id: wipro.id,
      employee_id: 'WIP-EMP-001',
      is_employee: true,
      is_verified: true,
      is_active: true,
    },
    {
      full_name: 'Guest User',
      phone: '+919999900005',
      email: null,
      role: Role.GUEST,
      tenant_id: null,
      employee_id: null,
      is_employee: false,
      is_verified: true,
      is_active: true,
    },
    {
      full_name: 'Vendor Owner Infosys',
      phone: '+919999900006',
      email: 'vendor1@infosys.com',
      role: Role.VENDOR,
      tenant_id: infosys.id,
      employee_id: null,
      is_employee: false,
      is_verified: true,
      is_active: true,
    },
    {
      full_name: 'Vendor Owner Wipro',
      phone: '+919999900008',
      email: 'vendor2@wipro.com',
      role: Role.VENDOR,
      tenant_id: wipro.id,
      employee_id: null,
      is_employee: false,
      is_verified: true,
      is_active: true,
    },
  ];

  const usersByPhone = new Map<string, Awaited<ReturnType<typeof prisma.user.upsert>>>();
  for (const user of seedUsers) {
    const upserted = await prisma.user.upsert({
      where: { phone: user.phone },
      update: {
        full_name: user.full_name,
        email: user.email,
        role: user.role,
        tenant_id: user.tenant_id,
        employee_id: user.employee_id,
        is_employee: user.is_employee,
        is_verified: user.is_verified,
        is_active: user.is_active,
        is_suspended: user.is_suspended ?? false,
        password_hash,
      },
      create: {
        full_name: user.full_name,
        phone: user.phone,
        email: user.email,
        role: user.role,
        tenant_id: user.tenant_id,
        employee_id: user.employee_id,
        is_employee: user.is_employee,
        is_verified: user.is_verified,
        is_active: user.is_active,
        is_suspended: user.is_suspended ?? false,
        password_hash,
      },
    });
    usersByPhone.set(user.phone, upserted);
  }

  for (const user of usersByPhone.values()) {
    await prisma.userProfile.upsert({
      where: { user_id: user.id },
      update: {
        full_name: user.full_name,
        employee_id: user.employee_id,
        department: user.role === Role.USER ? 'Engineering' : null,
        floor: user.role === Role.USER ? '3' : null,
        building: user.role === Role.USER ? 'Block A' : null,
        preferences: {
          dietary: user.role === Role.GUEST ? 'NONE' : 'VEG',
          notifications: { order: true, promo: user.role !== Role.GUEST },
          language: 'en',
        },
      },
      create: {
        user_id: user.id,
        full_name: user.full_name,
        employee_id: user.employee_id,
        department: user.role === Role.USER ? 'Engineering' : null,
        floor: user.role === Role.USER ? '3' : null,
        building: user.role === Role.USER ? 'Block A' : null,
        preferences: {
          dietary: user.role === Role.GUEST ? 'NONE' : 'VEG',
          notifications: { order: true, promo: user.role !== Role.GUEST },
          language: 'en',
        },
      },
    });
  }

  const vendorInfosys = usersByPhone.get('+919999900006');
  const vendorWipro = usersByPhone.get('+919999900008');
  if (!vendorInfosys || !vendorWipro) {
    throw new Error('Vendor users are required but were not seeded.');
  }

  await prisma.vendorProfile.upsert({
    where: { user_id: vendorInfosys.id },
    update: {
      business_name: 'Infosys Food Court Partner',
      business_address: 'Electronic City Campus Gate 2',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560100',
      gstin: '29ABCDE1234F1Z5',
      fssai_number: '12345678901234',
      bank_name: 'HDFC Bank',
      account_number: '111122223333',
      ifsc_code: 'HDFC0001234',
      is_verified: true,
    },
    create: {
      user_id: vendorInfosys.id,
      business_name: 'Infosys Food Court Partner',
      business_address: 'Electronic City Campus Gate 2',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560100',
      gstin: '29ABCDE1234F1Z5',
      fssai_number: '12345678901234',
      bank_name: 'HDFC Bank',
      account_number: '111122223333',
      ifsc_code: 'HDFC0001234',
      is_verified: true,
    },
  });

  await prisma.vendorProfile.upsert({
    where: { user_id: vendorWipro.id },
    update: {
      business_name: 'Wipro Canteen Vendor',
      business_address: 'Wipro Campus, Whitefield',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560066',
      gstin: '29ABCDE1234F1Z6',
      fssai_number: '22345678901234',
      bank_name: 'ICICI Bank',
      account_number: '444455556666',
      ifsc_code: 'ICIC0005678',
      is_verified: true,
    },
    create: {
      user_id: vendorWipro.id,
      business_name: 'Wipro Canteen Vendor',
      business_address: 'Wipro Campus, Whitefield',
      city: 'Bengaluru',
      state: 'Karnataka',
      pincode: '560066',
      gstin: '29ABCDE1234F1Z6',
      fssai_number: '22345678901234',
      bank_name: 'ICICI Bank',
      account_number: '444455556666',
      ifsc_code: 'ICIC0005678',
      is_verified: true,
    },
  });

  const opsAdmin = usersByPhone.get('+919999900002');
  if (!opsAdmin) {
    throw new Error('Ops admin user is required but was not seeded.');
  }

  const rosterTenants = [infosys, wipro, capgemini];
  for (const tenant of rosterTenants) {
    for (let i = 1; i <= 10; i += 1) {
      const employee_id = `${tenant.domain.split('.')[0].toUpperCase().slice(0, 3)}-EMP-${String(i).padStart(3, '0')}`;
      const email = `emp${String(i).padStart(3, '0')}@${tenant.domain}`;
      await prisma.employeeRoster.upsert({
        where: { tenant_id_employee_id: { tenant_id: tenant.id, employee_id } },
        update: {
          email,
          full_name: `${tenant.name} Employee ${String(i).padStart(3, '0')}`,
          department: i % 2 === 0 ? 'Operations' : 'Engineering',
          is_active: true,
          uploaded_by: opsAdmin.id,
        },
        create: {
          tenant_id: tenant.id,
          employee_id,
          email,
          full_name: `${tenant.name} Employee ${String(i).padStart(3, '0')}`,
          department: i % 2 === 0 ? 'Operations' : 'Engineering',
          is_active: true,
          uploaded_by: opsAdmin.id,
        },
      });
    }
  }

  // Ensure contract-referenced seeded users exist in roster.
  await prisma.employeeRoster.upsert({
    where: { tenant_id_employee_id: { tenant_id: infosys.id, employee_id: 'INF-EMP-001' } },
    update: { email: 'emp001@infosys.com', full_name: 'Infosys Employee 001', department: 'Engineering', is_active: true, uploaded_by: opsAdmin.id },
    create: {
      tenant_id: infosys.id,
      employee_id: 'INF-EMP-001',
      email: 'emp001@infosys.com',
      full_name: 'Infosys Employee 001',
      department: 'Engineering',
      is_active: true,
      uploaded_by: opsAdmin.id,
    },
  });

  await prisma.employeeRoster.upsert({
    where: { tenant_id_employee_id: { tenant_id: wipro.id, employee_id: 'WIP-EMP-001' } },
    update: { email: 'emp001@wipro.com', full_name: 'Wipro Employee 001', department: 'Engineering', is_active: true, uploaded_by: opsAdmin.id },
    create: {
      tenant_id: wipro.id,
      employee_id: 'WIP-EMP-001',
      email: 'emp001@wipro.com',
      full_name: 'Wipro Employee 001',
      department: 'Engineering',
      is_active: true,
      uploaded_by: opsAdmin.id,
    },
  });

  const allRoles: Role[] = [Role.SUPER_ADMIN, Role.TECH_ADMIN, Role.OPS_ADMIN, Role.VENDOR, Role.USER, Role.GUEST];
  const allModules: AppModule[] = [
    AppModule.AUTH,
    AppModule.VENDOR,
    AppModule.ORDER,
    AppModule.MENU,
    AppModule.REPORT,
    AppModule.SETTINGS,
    AppModule.EMPLOYEE,
    AppModule.DELEGATION,
    AppModule.TENANT,
    AppModule.SESSION,
    AppModule.FINANCE,
  ];

  for (const role of allRoles) {
    for (const module of allModules) {
      const perms = buildPermissions(role, module);
      await prisma.rolePermission.upsert({
        where: { role_module: { role, module } },
        update: perms,
        create: { role, module, ...perms },
      });
    }
  }

  const superAdmin = usersByPhone.get('+919999900001');
  const techAdmin = usersByPhone.get('+919999900003');
  const infosysEmployee = usersByPhone.get('+919999900004');
  const guestUser = usersByPhone.get('+919999900005');
  if (!superAdmin || !techAdmin || !infosysEmployee || !guestUser) {
    throw new Error('Expected core users missing after seed.');
  }

  const auditSeed = [
    { id: 'seed-audit-1', user_id: superAdmin.id, tenant_id: infosys.id, action: AuditAction.ADMIN_LOGIN, module: AuditModule.AUTH, metadata: { source: 'seed' } },
    { id: 'seed-audit-2', user_id: infosysEmployee.id, tenant_id: infosys.id, action: AuditAction.USER_LOGIN, module: AuditModule.AUTH, metadata: { source: 'seed' } },
    { id: 'seed-audit-3', user_id: vendorInfosys.id, tenant_id: infosys.id, action: AuditAction.VENDOR_LOGIN, module: AuditModule.AUTH, metadata: { source: 'seed' } },
    { id: 'seed-audit-4', user_id: opsAdmin.id, tenant_id: infosys.id, action: AuditAction.BULK_EMPLOYEE_UPLOAD, module: AuditModule.EMPLOYEE, metadata: { source: 'seed', rows: 10 } },
    { id: 'seed-audit-5', user_id: guestUser.id, tenant_id: null, action: AuditAction.GUEST_REGISTER, module: AuditModule.AUTH, metadata: { source: 'seed' } },
  ];

  await prisma.auditLog.createMany({
    data: auditSeed.map((log) => ({
      id: log.id,
      user_id: log.user_id,
      tenant_id: log.tenant_id,
      action: log.action,
      module: log.module,
      ip_address: '127.0.0.1',
      device: 'seed-script',
      metadata: log.metadata,
    })),
    skipDuplicates: true,
  });

  await prisma.bulkUploadLog.upsert({
    where: { id: 'seed-bulk-upload-1' },
    update: {
      tenant_id: infosys.id,
      uploaded_by: opsAdmin.id,
      file_name: 'employee_roster_infosys_seed.csv',
      gcs_path: 'seed/employee_roster_infosys_seed.csv',
      total_records: 12,
      success_count: 12,
      failed_count: 0,
      status: UploadStatus.COMPLETED,
    },
    create: {
      id: 'seed-bulk-upload-1',
      tenant_id: infosys.id,
      uploaded_by: opsAdmin.id,
      file_name: 'employee_roster_infosys_seed.csv',
      gcs_path: 'seed/employee_roster_infosys_seed.csv',
      total_records: 12,
      success_count: 12,
      failed_count: 0,
      status: UploadStatus.COMPLETED,
    },
  });

  const now = Date.now();
  await prisma.session.deleteMany({ where: { refresh_token: { startsWith: 'seed-' } } });
  for (const user of usersByPhone.values()) {
    for (let i = 1; i <= 2; i += 1) {
      await prisma.session.create({
        data: {
          user_id: user.id,
          refresh_token: `seed-${user.id}-${i}-${now}`,
          device: i === 1 ? 'iPhone 15' : 'Pixel 8',
          ip_address: i === 1 ? '10.0.0.10' : '10.0.0.11',
          is_revoked: false,
          expires_at: new Date(now + 7 * 24 * 60 * 60 * 1000),
        },
      });
    }
  }

  await prisma.delegation.upsert({
    where: { id: 'seed-delegation-auth' },
    update: {
      is_active: true,
      starts_at: new Date(now),
      expires_at: new Date(now + 24 * 60 * 60 * 1000),
    },
    create: {
      id: 'seed-delegation-auth',
      delegator_id: superAdmin.id,
      delegatee_id: techAdmin.id,
      module: AppModule.AUTH,
      reason: 'Seeded temporary delegation',
      is_active: true,
      starts_at: new Date(now),
      expires_at: new Date(now + 24 * 60 * 60 * 1000),
    },
  });

  await prisma.contactChangeRequest.upsert({
    where: { id: 'seed-contact-change-1' },
    update: { status: ContactStatus.PENDING, otp_verified: false },
    create: {
      id: 'seed-contact-change-1',
      user_id: infosysEmployee.id,
      type: ContactType.EMAIL,
      old_value: 'emp001@infosys.com',
      new_value: 'emp001.new@infosys.com',
      otp_verified: false,
      status: ContactStatus.PENDING,
    },
  });

  await prisma.guestUpgradeRequest.upsert({
    where: { user_id: guestUser.id },
    update: {
      employee_id: 'INF-EMP-009',
      work_email: 'emp009@infosys.com',
      tenant_id: infosys.id,
      status: UpgradeStatus.PENDING,
    },
    create: {
      user_id: guestUser.id,
      employee_id: 'INF-EMP-009',
      work_email: 'emp009@infosys.com',
      tenant_id: infosys.id,
      status: UpgradeStatus.PENDING,
    },
  });

  console.log('Seed complete: tenants, settings, users, profiles, roster, RBAC, audit logs, sessions.');
}

main()
  .catch((error) => {
    console.error('Seed failed:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
