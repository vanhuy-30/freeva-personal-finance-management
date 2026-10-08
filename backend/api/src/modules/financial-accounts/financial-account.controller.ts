import { Body, Controller, Delete, Get, Header, HttpCode, Param, Patch, Post, Query, Req, Res, UseFilters, UseGuards } from '@nestjs/common';
import type { Response } from 'express';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AccountIdDto, AccountQueryDto, ArchiveAccountDto, CreateAccountDto, UpdateAccountDto } from './financial-account.dto';
import { FinancialAccountService } from './financial-account.service';
import { FinancialAccountExceptionFilter } from './financial-account-exception.filter';

@Controller('v1/financial-accounts')
@UseGuards(AuthGuard)
@UseFilters(FinancialAccountExceptionFilter)
export class FinancialAccountController {
  constructor(private readonly accounts: FinancialAccountService) {}

  @Post() @Header('Cache-Control', 'no-store')
  async create(@Req() request: AuthRequest, @Body() body: CreateAccountDto, @Res({ passthrough: true }) res: Response) {
    const result = await this.accounts.create(request.session.userId, body);
    res.status(result.created ? 201 : 200);
    return result.account;
  }
  @Get() @Header('Cache-Control', 'no-store')
  list(@Req() request: AuthRequest, @Query() query: AccountQueryDto) {
    return this.accounts.list(request.session.userId, query);
  }
  @Get(':id') @Header('Cache-Control', 'no-store')
  find(@Req() request: AuthRequest, @Param() params: AccountIdDto) {
    return this.accounts.find(request.session.userId, params.id);
  }
  @Patch(':id') @Header('Cache-Control', 'no-store')
  update(@Req() request: AuthRequest, @Param() params: AccountIdDto, @Body() body: UpdateAccountDto) {
    return this.accounts.update(request.session.userId, params.id, body);
  }
  @Delete(':id') @HttpCode(204) @Header('Cache-Control', 'no-store')
  archive(@Req() request: AuthRequest, @Param() params: AccountIdDto, @Query() query: ArchiveAccountDto) {
    return this.accounts.archive(request.session.userId, params.id, query.version);
  }
}
