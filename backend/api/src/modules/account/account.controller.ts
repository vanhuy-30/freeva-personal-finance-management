import { Controller, Delete, Get, Header, HttpCode, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AccountExceptionFilter } from './account-exception.filter';
import { AccountService } from './account.service';

@Controller('v1/account')
@UseGuards(AuthGuard)
@UseFilters(AccountExceptionFilter)
export class AccountController {
  constructor(private readonly accounts: AccountService) {}

  @Get('export')
  @Header('Cache-Control', 'no-store')
  export(@Req() request: AuthRequest) {
    return this.accounts.export(request.session.userId);
  }

  @Delete()
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  remove(@Req() request: AuthRequest) {
    return this.accounts.remove(request.session.userId);
  }
}
