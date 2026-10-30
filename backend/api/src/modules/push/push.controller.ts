import {
  Body, Controller, Delete, Header, HttpCode, Put, Req, UseGuards,
} from '@nestjs/common';
import { AuthGuard, type AuthRequest } from '../auth/auth.guard';
import { PutPushTokenDto } from './push.dto';
import { PushService } from './push.service';

@Controller()
@UseGuards(AuthGuard)
export class PushController {
  constructor(private readonly push: PushService) {}

  @Put('v1/push-tokens') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async put(@Req() req: AuthRequest, @Body() body: PutPushTokenDto): Promise<void> {
    await this.push.register({
      userId: req.session.userId,
      sessionId: req.session.id,
      token: body.token,
      platform: body.platform,
    });
  }

  @Delete('v1/push-tokens') @HttpCode(204) @Header('Cache-Control', 'no-store')
  async remove(@Req() req: AuthRequest): Promise<void> {
    await this.push.unregister(req.session.id);
  }
}
