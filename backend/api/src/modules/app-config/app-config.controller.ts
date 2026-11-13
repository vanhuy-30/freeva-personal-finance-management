import { Controller, Get, Header, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AppConfigExceptionFilter } from './app-config-exception.filter';
import { AppConfigService } from './app-config.service';

@Controller('v1/app-config')
@UseGuards(AuthGuard)
@UseFilters(AppConfigExceptionFilter)
export class AppConfigController {
  constructor(private readonly appConfig: AppConfigService) {}

  @Get() @Header('Cache-Control', 'no-store')
  get(@Req() req: AuthRequest) {
    return this.appConfig.forUser(req.session.userId);
  }
}
