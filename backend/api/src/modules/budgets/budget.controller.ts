import {
  Body, Controller, Delete, Get, Header, HttpCode, Put, Query, Req, UseFilters, UseGuards,
} from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { BudgetExceptionFilter } from './budget-exception.filter';
import { BudgetQueryDto, DeleteBudgetDto, PutBudgetDto } from './budget.dto';
import { BudgetService } from './budget.service';

@Controller('v1/budgets')
@UseGuards(AuthGuard)
@UseFilters(BudgetExceptionFilter)
export class BudgetController {
  constructor(private readonly budgets: BudgetService) {}

  @Get('current') @Header('Cache-Control', 'no-store')
  current(@Req() req: AuthRequest, @Query() query: BudgetQueryDto) {
    return this.budgets.current(req.session.userId, query);
  }

  @Put('current') @Header('Cache-Control', 'no-store')
  put(@Req() req: AuthRequest, @Body() body: PutBudgetDto) {
    return this.budgets.put(req.session.userId, body);
  }

  @Delete('current') @HttpCode(204) @Header('Cache-Control', 'no-store')
  delete(@Req() req: AuthRequest, @Query() query: DeleteBudgetDto) {
    return this.budgets.delete(req.session.userId, query);
  }
}
