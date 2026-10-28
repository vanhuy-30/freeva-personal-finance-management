import {
  Body, Controller, Get, Header, HttpCode, Param, Post, Put, Req, UseFilters, UseGuards,
} from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { NotificationExceptionFilter } from './notification-exception.filter';
import { NotificationIdParamDto, PutNotificationPreferencesDto } from './notification.dto';
import { NotificationService } from './notification.service';

@Controller()
@UseGuards(AuthGuard)
@UseFilters(NotificationExceptionFilter)
export class NotificationController {
  constructor(private readonly notifications: NotificationService) {}

  @Get('v1/notification-preferences') @Header('Cache-Control', 'no-store')
  preferences(@Req() req: AuthRequest) {
    return this.notifications.getPreferences(req.session.userId);
  }

  @Put('v1/notification-preferences') @Header('Cache-Control', 'no-store')
  putPreferences(@Req() req: AuthRequest, @Body() body: PutNotificationPreferencesDto) {
    return this.notifications.putPreferences(req.session.userId, body);
  }

  @Get('v1/notifications') @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest) {
    return this.notifications.list(req.session.userId);
  }

  @Post('v1/notifications/:id/read') @Header('Cache-Control', 'no-store')
  markRead(@Req() req: AuthRequest, @Param() params: NotificationIdParamDto) {
    return this.notifications.markRead(req.session.userId, params.id);
  }

  @Post('v1/notifications/read-all') @HttpCode(200) @Header('Cache-Control', 'no-store')
  markAllRead(@Req() req: AuthRequest) {
    return this.notifications.markAllRead(req.session.userId);
  }

  @Post('v1/notifications/evaluate') @HttpCode(200) @Header('Cache-Control', 'no-store')
  evaluate(@Req() req: AuthRequest) {
    return this.notifications.evaluate(req.session.userId);
  }
}
