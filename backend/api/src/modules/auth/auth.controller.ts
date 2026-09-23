import {
  Body,
  Controller,
  Delete,
  Get,
  Header,
  HttpCode,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseFilters,
  UseGuards,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthGuard, type AuthRequest } from './auth.guard';
import { AuthRateLimitGuard } from './auth-rate-limit.guard';
import { AuthExceptionFilter } from './auth-exception.filter';
import {
  CredentialsDto,
  EmailDto,
  ResetPasswordDto,
  TokenDto,
} from './dto/auth.dto';

@Controller('v1/auth')
@UseFilters(AuthExceptionFilter)
@UseGuards(AuthRateLimitGuard)
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('email-step')
  @HttpCode(200)
  @Header('Cache-Control', 'no-store')
  emailStep(@Body() body: EmailDto) {
    return this.auth.emailStep(body.email);
  }

  @Post('register')
  @HttpCode(202)
  register(@Body() body: CredentialsDto) {
    return this.auth.register(body.email, body.password);
  }

  @Post('login')
  @HttpCode(200)
  @Header('Cache-Control', 'no-store')
  login(@Body() body: CredentialsDto) {
    return this.auth.login(body.email, body.password);
  }

  @Post('email-verifications')
  @HttpCode(202)
  requestVerification(@Body() body: EmailDto) {
    return this.auth.requestEmail(body.email, 'verify_email');
  }

  @Post('verify-email')
  @HttpCode(204)
  verifyEmail(@Body() body: TokenDto) {
    return this.auth.consume(body.token, 'verify_email');
  }

  @Post('password-resets')
  @HttpCode(202)
  requestReset(@Body() body: EmailDto) {
    return this.auth.requestEmail(body.email, 'reset_password');
  }

  @Post('reset-password')
  @HttpCode(204)
  resetPassword(@Body() body: ResetPasswordDto) {
    return this.auth.consume(body.token, 'reset_password', body.password);
  }

  @Post('logout')
  @HttpCode(204)
  @UseGuards(AuthGuard)
  logout(@Req() request: AuthRequest) {
    return this.auth.revoke(request.session.userId, request.session.id);
  }
}

@Controller('v1/sessions')
@UseFilters(AuthExceptionFilter)
@UseGuards(AuthGuard)
export class SessionsController {
  constructor(private readonly auth: AuthService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  list(@Req() request: AuthRequest) {
    return this.auth.sessions(request.session.userId, request.session.id);
  }

  @Delete()
  @HttpCode(204)
  revokeAll(@Req() request: AuthRequest) {
    return this.auth.revoke(request.session.userId);
  }

  @Delete(':sessionId')
  @HttpCode(204)
  revoke(
    @Req() request: AuthRequest,
    @Param('sessionId', new ParseUUIDPipe({ version: '4' })) sessionId: string,
  ) {
    return this.auth.revoke(request.session.userId, sessionId);
  }
}
