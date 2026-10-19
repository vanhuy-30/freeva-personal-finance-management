import { Controller, Get, Header, Query, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { ReportError } from './domain/report';
import { CashflowQueryDto } from './report.dto';
import { ReportExceptionFilter } from './report-exception.filter';
import { ReportService } from './report.service';

@Controller('v1/reports')
@UseGuards(AuthGuard)
@UseFilters(ReportExceptionFilter)
export class ReportController {
  constructor(private readonly reports: ReportService) {}

  @Get('cashflow') @Header('Cache-Control', 'no-store')
  cashflow(@Req() request: AuthRequest, @Query() query: CashflowQueryDto) {
    return this.reports.cashflow(request.session.userId, query);
  }

  @Get('net-worth') @Header('Cache-Control', 'no-store')
  netWorth(@Req() request: AuthRequest, @Query() query: Record<string, unknown>) {
    if (Object.keys(query).length > 0) throw new ReportError('VALIDATION_ERROR');
    return this.reports.netWorth(request.session.userId);
  }
}
