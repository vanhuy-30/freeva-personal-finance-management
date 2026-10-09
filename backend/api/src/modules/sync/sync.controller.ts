import { Body, Controller, Header, HttpCode, Post, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { SyncExceptionFilter } from './sync-exception.filter';
import { SyncRequestDto } from './sync.dto';
import { SyncService } from './sync.service';

@Controller('v1/sync')
@UseGuards(AuthGuard)
@UseFilters(SyncExceptionFilter)
export class SyncController {
  constructor(private readonly sync: SyncService) {}
  @Post() @HttpCode(200) @Header('Cache-Control', 'no-store')
  apply(@Req() request: AuthRequest, @Body() body: SyncRequestDto) {
    return this.sync.apply(request.session.userId, body);
  }
}
