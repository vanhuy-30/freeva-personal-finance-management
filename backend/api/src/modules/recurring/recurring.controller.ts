import {
  Body, Controller, Delete, Get, Header, Headers, HttpCode, Param, Patch, Post, Query, Req, Res, UseFilters, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { RecurringError } from './domain/recurring';
import { CreateRecurringDto, DeleteRecurringDto, RecurringIdDto, RecurringQueryDto, UpdateRecurringDto } from './recurring.dto';
import { RecurringExceptionFilter } from './recurring-exception.filter';
import { RecurringService } from './recurring.service';

@Controller('v1/recurring-transactions')
@UseGuards(AuthGuard)
@UseFilters(RecurringExceptionFilter)
export class RecurringController {
  constructor(private readonly recurring: RecurringService) {}

  @Post() @Header('Cache-Control', 'no-store')
  async create(
    @Req() req: AuthRequest,
    @Body() body: CreateRecurringDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    if (!idempotencyKey || idempotencyKey.toLowerCase() !== body.clientId) {
      throw new RecurringError('VALIDATION_ERROR');
    }
    const result = await this.recurring.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.rule;
  }

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: RecurringQueryDto) {
    return this.recurring.list(req.session.userId, query);
  }

  @Post('run') @HttpCode(200) @Header('Cache-Control', 'no-store')
  run(@Req() req: AuthRequest) {
    return this.recurring.run(req.session.userId);
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param() params: RecurringIdDto) {
    return this.recurring.find(req.session.userId, params.id);
  }

  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param() params: RecurringIdDto, @Body() body: UpdateRecurringDto) {
    return this.recurring.update(req.session.userId, params.id, body);
  }

  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  delete(@Req() req: AuthRequest, @Param() params: RecurringIdDto, @Query() query: DeleteRecurringDto) {
    return this.recurring.delete(req.session.userId, params.id, query.version);
  }
}
