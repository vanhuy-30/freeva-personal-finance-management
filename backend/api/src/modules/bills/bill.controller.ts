import {
  Body, Controller, Delete, Get, Header, Headers, HttpCode, Param, Patch, Post, Query, Req, Res, UseFilters, UseGuards,
} from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { BillError } from './domain/bill';
import {
  BillIdDto,
  BillQueryDto,
  CreateBillDto,
  DeleteBillDto,
  PayBillDto,
  UnpayBillDto,
  UpdateBillDto,
} from './bill.dto';
import { BillExceptionFilter } from './bill-exception.filter';
import { BillService } from './bill.service';

@Controller('v1/bills')
@UseGuards(AuthGuard)
@UseFilters(BillExceptionFilter)
export class BillController {
  constructor(private readonly bills: BillService) {}

  @Post() @Header('Cache-Control', 'no-store')
  async create(
    @Req() req: AuthRequest,
    @Body() body: CreateBillDto,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ) {
    if (!idempotencyKey || idempotencyKey.toLowerCase() !== body.clientId) {
      throw new BillError('VALIDATION_ERROR');
    }
    const result = await this.bills.create(req.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.bill;
  }

  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() req: AuthRequest, @Query() query: BillQueryDto) {
    return this.bills.list(req.session.userId, query);
  }

  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() req: AuthRequest, @Param() params: BillIdDto) {
    return this.bills.find(req.session.userId, params.id);
  }

  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() req: AuthRequest, @Param() params: BillIdDto, @Body() body: UpdateBillDto) {
    return this.bills.update(req.session.userId, params.id, body);
  }

  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  delete(@Req() req: AuthRequest, @Param() params: BillIdDto, @Query() query: DeleteBillDto) {
    return this.bills.delete(req.session.userId, params.id, query.version);
  }

  @Post(':id/pay') @Header('Cache-Control', 'no-store')
  pay(@Req() req: AuthRequest, @Param() params: BillIdDto, @Body() body: PayBillDto) {
    return this.bills.pay(req.session.userId, params.id, body);
  }

  @Post(':id/unpay') @Header('Cache-Control', 'no-store')
  unpay(@Req() req: AuthRequest, @Param() params: BillIdDto, @Body() body: UnpayBillDto) {
    return this.bills.unpay(req.session.userId, params.id, body);
  }
}
