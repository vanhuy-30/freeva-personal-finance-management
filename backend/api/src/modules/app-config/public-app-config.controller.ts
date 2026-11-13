import { Controller, Get, Header, UseFilters } from '@nestjs/common';
import { AppConfigExceptionFilter } from './app-config-exception.filter';
import { AppConfigReader } from './app-config.reader';

/**
 * BE-P5-001: config numbers without a session, for screens before sign-in (password rules…).
 * No flags (they are per user) and no user data. Served from the reader cache (≤ 30 s old).
 */
@Controller('v1/app-config/public')
@UseFilters(AppConfigExceptionFilter)
export class PublicAppConfigController {
  constructor(private readonly reader: AppConfigReader) {}

  @Get() @Header('Cache-Control', 'no-store')
  get() {
    return this.reader.published();
  }
}
