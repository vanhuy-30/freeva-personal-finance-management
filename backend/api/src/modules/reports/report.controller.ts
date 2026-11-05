import { Controller, Get, Header, Query, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { CashflowQueryDto, MonthReviewQueryDto, NetWorthQueryDto, SeriesQueryDto, TrendQueryDto } from './report.dto';
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

  @Get('month-review') @Header('Cache-Control', 'no-store')
  monthReview(@Req() request: AuthRequest, @Query() query: MonthReviewQueryDto) {
    return this.reports.monthReview(request.session.userId, query);
  }

  @Get('trend') @Header('Cache-Control', 'no-store')
  trend(@Req() request: AuthRequest, @Query() query: TrendQueryDto) {
    return this.reports.trend(request.session.userId, query);
  }

  @Get('series') @Header('Cache-Control', 'no-store')
  series(@Req() request: AuthRequest, @Query() query: SeriesQueryDto) {
    return this.reports.series(request.session.userId, query);
  }

  @Get('net-worth') @Header('Cache-Control', 'no-store')
  netWorth(@Req() request: AuthRequest, @Query() query: NetWorthQueryDto) {
    return this.reports.netWorth(request.session.userId, query.displayCurrency);
  }
}
