import {
  Body,
  Controller,
  NotFoundException,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import { StaffAuthGuard } from '../staff-auth/staff-auth.guard';
import type { StaffRequest } from '../staff-auth/staff-principal';
import { AdminUserLookupService } from './admin-user-lookup.service';
import { StaffUserLookupDto } from './dto/staff-user-lookup.dto';

@Controller('admin/user-lookups')
@UseGuards(StaffAuthGuard)
export class AdminUserLookupController {
  constructor(private readonly userLookup: AdminUserLookupService) {}

  @Post()
  async lookup(@Req() request: StaffRequest, @Body() body: StaffUserLookupDto) {
    const user = await this.userLookup.lookup(request.staff.id, body);
    if (!user) {
      throw new NotFoundException({
        error: {
          code: 'USER_NOT_FOUND',
          message: 'User account was not found',
        },
      });
    }
    return user;
  }
}
