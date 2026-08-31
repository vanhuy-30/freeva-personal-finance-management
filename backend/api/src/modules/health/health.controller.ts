import { Controller, Get, ServiceUnavailableException } from '@nestjs/common';
import { HealthService } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  async getHealth() {
    const result = await this.healthService.check();
    if (result.database === 'down') {
      throw new ServiceUnavailableException({
        error: {
          code: 'DATABASE_UNAVAILABLE',
          message: 'Database is not reachable',
        },
      });
    }
    return result;
  }
}
