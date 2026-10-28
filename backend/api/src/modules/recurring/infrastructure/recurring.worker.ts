import { Injectable, Logger, OnApplicationBootstrap, OnModuleDestroy } from '@nestjs/common';
import { RecurringService } from '../recurring.service';

@Injectable()
export class RecurringWorker implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(RecurringWorker.name);
  private timer?: NodeJS.Timeout;
  private running?: Promise<void>;

  constructor(private readonly recurring: RecurringService) {}

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
      const result = await this.recurring.runAll();
      if (result.created > 0 || result.skipped > 0) {
        this.logger.log({ created: result.created, skipped: result.skipped }, 'recurring.run');
      }
    } catch (error) {
      const code = error instanceof Error ? error.message : 'unknown';
      this.logger.warn({ code }, 'recurring.run.failed');
    }
  }
}
