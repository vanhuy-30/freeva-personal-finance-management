import { Controller, Get, Header, Query, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { CalendarExceptionFilter } from './calendar-exception.filter';
import { CalendarQueryDto } from './calendar.dto';
import { CalendarService } from './calendar.service';

@Controller('v1/calendar')
@UseGuards(AuthGuard)
@UseFilters(CalendarExceptionFilter)
export class CalendarController {
  constructor(private readonly calendar: CalendarService) {}

  @Get() @Header('Cache-Control', 'no-store')
  month(@Req() req: AuthRequest, @Query() query: CalendarQueryDto) {
    return this.calendar.month(req.session.userId, query.month);
  }
}
