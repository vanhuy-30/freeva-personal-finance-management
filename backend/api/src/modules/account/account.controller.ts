import { Body, Controller, Delete, Header, HttpCode, Post, Req, UseFilters, UseGuards } from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AuthService } from '../auth/auth.service';
import { ConfirmIdentityDto } from '../auth/dto/auth.dto';
import { AccountExceptionFilter } from './account-exception.filter';
import { AccountService } from './account.service';

/** Whole-account export and delete. Both need the password again (or a fresh OAuth session): SEC-P6-002. */
@Controller('v1/account')
@UseGuards(AuthGuard)
@UseFilters(AccountExceptionFilter)
export class AccountController {
  constructor(
    private readonly accounts: AccountService,
    private readonly auth: AuthService,
  ) {}

  @Post('export')
  @HttpCode(200)
  @Header('Cache-Control', 'no-store')
  async export(@Req() request: AuthRequest, @Body() body: ConfirmIdentityDto) {
    await this.auth.confirmIdentity(request.session, body.password);
    return this.accounts.export(request.session.userId);
  }

  @Delete()
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async remove(@Req() request: AuthRequest, @Body() body: ConfirmIdentityDto) {
    await this.auth.confirmIdentity(request.session, body.password);
    await this.accounts.remove(request.session.userId);
  }
}
