import {
  Body, Controller, Get, Header, Put, Req, UseFilters, UseGuards,
} from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { AuthExceptionFilter } from '../auth/auth-exception.filter';
import { UpdateProfileDto } from './profile.dto';
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

  @Put()
  @Header('Cache-Control', 'no-store')
  update(@Req() request: AuthRequest, @Body() body: UpdateProfileDto) {
    return this.profiles.update(request.session.userId, body);
  }
}
