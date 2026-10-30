import {
  Body, Controller, Get, Header, HttpCode, Patch, Put, Req, UseFilters, UseGuards,
} from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AuthExceptionFilter } from '../auth/auth-exception.filter';
import { DisplayCurrencyDto, OnboardingAnswersDto, UpdateProfileDto } from './profile.dto';
import { ProfileService } from './profile.service';

@Controller('v1/profile')
@UseGuards(AuthGuard)
@UseFilters(AuthExceptionFilter)
export class ProfileController {
  constructor(private readonly profiles: ProfileService) {}

  @Get()
  @Header('Cache-Control', 'no-store')
  get(@Req() request: AuthRequest) {
    return this.profiles.get(request.session.userId);
  }

  @Get('options')
  @Header('Cache-Control', 'no-store')
  options() {
    return this.profiles.options();
  }

  @Patch('onboarding')
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async saveOnboarding(@Req() request: AuthRequest, @Body() body: OnboardingAnswersDto) {
    await this.profiles.saveOnboarding(request.session.userId, body);
  }

  @Put('display-currency')
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async saveDisplayCurrency(@Req() request: AuthRequest, @Body() body: DisplayCurrencyDto) {
    await this.profiles.saveDisplayCurrency(request.session.userId, body.currencyCode);
  }

  @Put()
  @Header('Cache-Control', 'no-store')
  update(@Req() request: AuthRequest, @Body() body: UpdateProfileDto) {
    return this.profiles.update(request.session.userId, body);
  }
}
