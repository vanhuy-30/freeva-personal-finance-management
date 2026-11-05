import { Injectable, Logger, OnApplicationBootstrap, OnModuleDestroy } from '@nestjs/common';
import { NotificationService } from '../notification.service';

@Injectable()
export class NotificationWorker implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(NotificationWorker.name);
  private timer?: NodeJS.Timeout;
  private running?: Promise<void>;

  constructor(private readonly notifications: NotificationService) {}

  onApplicationBootstrap(): void {
    if (process.env.NODE_ENV === 'test') return;
    this.timer = setInterval(() => {
      void this.flush();
    }, 60_000);
    this.timer.unref();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    await this.running;
  }

  flush(): Promise<void> {
    if (this.running) return this.running;
    this.running = this.tick().finally(() => {
      this.running = undefined;
    });
    return this.running;
  }

  private async tick(): Promise<void> {
    try {
      const result = await this.notifications.evaluate(null);
      if (result.created > 0) {
        this.logger.log({ created: result.created }, 'notifications.evaluate');
      }
    } catch (error) {
      const code = error instanceof Error ? error.message : 'unknown';
      this.logger.warn({ code }, 'notifications.evaluate.failed');
    }
  }
}
