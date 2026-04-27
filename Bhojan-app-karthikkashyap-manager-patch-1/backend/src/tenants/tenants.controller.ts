import { Controller, Get, Post, Param, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { TenantsService } from './services/tenants.service.js';
import { IsUUID } from 'class-validator';

class ValidateTenantDto {
  @IsUUID()
  tenant_id: string;
}

@Controller('tenants')
export class TenantsController {
  constructor(private service: TenantsService) {}

  // EP-35
  @Get()
  findAll() {
    return this.service.findAllActive();
  }

  // EP-36
  @Get(':id/settings')
  getSettings(@Param('id') id: string) {
    return this.service.getSettings(id);
  }

  // EP-37
  @Post('validate')
  @HttpCode(HttpStatus.OK)
  validate(@Body() body: ValidateTenantDto) {
    return this.service.validate(body.tenant_id);
  }
}
