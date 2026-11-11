import { Body, Controller, Delete, Get, Header, Param, Put, Query, Req, UseFilters, UseGuards } from '@nestjs/common';
import { StaffAuthGuard } from '../staff-auth/staff-auth.guard';
import type { StaffRequest } from '../staff-auth/staff-principal';
import { AppConfigExceptionFilter } from './app-config-exception.filter';
import { ResetConfigValueQueryDto, UpdateConfigValueDto, UpdateFlagDto } from './app-config.dto';
import { AppConfigService } from './app-config.service';

@Controller('admin/app-config')
@UseGuards(StaffAuthGuard)
@UseFilters(AppConfigExceptionFilter)
export class AdminAppConfigController {
  constructor(private readonly appConfig: AppConfigService) {}

  @Get() @Header('Cache-Control', 'no-store')
  list() {
    return this.appConfig.forStaff();
  }

  @Put('flags/:key') @Header('Cache-Control', 'no-store')
  updateFlag(@Req() request: StaffRequest, @Param('key') key: string, @Body() body: UpdateFlagDto) {
    return this.appConfig.updateFlag(request.staff.id, key, body);
  }

  @Put('values/:key') @Header('Cache-Control', 'no-store')
  updateValue(@Req() request: StaffRequest, @Param('key') key: string, @Body() body: UpdateConfigValueDto) {
    return this.appConfig.updateValue(request.staff.id, key, body);
  }

  @Delete('values/:key') @Header('Cache-Control', 'no-store')
  resetValue(@Req() request: StaffRequest, @Param('key') key: string, @Query() query: ResetConfigValueQueryDto) {
    return this.appConfig.resetValue(request.staff.id, key, query.version);
  }
}
