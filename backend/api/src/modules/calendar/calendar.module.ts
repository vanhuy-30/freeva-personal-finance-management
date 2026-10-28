import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { CalendarController } from './calendar.controller';
import { CalendarService } from './calendar.service';
import { CALENDAR_REPOSITORY } from './domain/calendar.repository';
import { PrismaCalendarRepository } from './infrastructure/prisma-calendar.repository';

@Module({
  imports: [AuthModule],
  controllers: [CalendarController],
  providers: [
    CalendarService,
    { provide: CALENDAR_REPOSITORY, useClass: PrismaCalendarRepository },
  ],
  exports: [CalendarService],
})
export class CalendarModule {}
