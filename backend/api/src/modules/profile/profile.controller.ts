import {
  Body, Controller, Delete, Get, Header, HttpCode, Patch, Put, Req, UseFilters, UseGuards,
} from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AuthExceptionFilter } from '../auth/auth-exception.filter';
import { AutoSuggestDto, AvatarDto, DisplayCurrencyDto, DeclaredIncomeUpdateDto, OnboardingAnswersDto, UpdateProfileDto } from './profile.dto';
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

  @Put('declared-income')
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async saveDeclaredIncome(@Req() request: AuthRequest, @Body() body: DeclaredIncomeUpdateDto) {
    await this.profiles.saveDeclaredIncome(request.session.userId, body.declaredIncome);
  }

  @Put('display-currency')
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async saveDisplayCurrency(@Req() request: AuthRequest, @Body() body: DisplayCurrencyDto) {
    await this.profiles.saveDisplayCurrency(request.session.userId, body.currencyCode);
  }

  @Put('auto-suggest')
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async saveAutoSuggest(@Req() request: AuthRequest, @Body() body: AutoSuggestDto) {
    await this.profiles.saveAutoSuggest(request.session.userId, body.enabled);
  }

  @Put('avatar')
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async saveAvatar(@Req() request: AuthRequest, @Body() body: AvatarDto) {
    await this.profiles.saveAvatar(request.session.userId, body.imageBase64);
  }

  @Get('avatar')
  @Header('Cache-Control', 'no-store')
  async avatar(@Req() request: AuthRequest) {
    const { image, updatedAt } = await this.profiles.avatar(request.session.userId);
    return { imageBase64: image.toString('base64'), updatedAt: updatedAt.toISOString() };
  }

  @Delete('avatar')
  @HttpCode(204)
  @Header('Cache-Control', 'no-store')
  async deleteAvatar(@Req() request: AuthRequest) {
    await this.profiles.deleteAvatar(request.session.userId);
  }

  @Put()
  @Header('Cache-Control', 'no-store')
  update(@Req() request: AuthRequest, @Body() body: UpdateProfileDto) {
    return this.profiles.update(request.session.userId, body);
  }
}
