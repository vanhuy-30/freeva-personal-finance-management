import {
  Inject,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnApplicationBootstrap,
} from '@nestjs/common';
import { EMAIL_SENDER, type EmailSender } from '../../mail/domain/email-sender';
import {
  AUTH_REPOSITORY,
  type AuthRepository,
} from '../domain/auth.repository';
import { AuthCrypto } from './auth-crypto';

@Injectable()
export class AuthMailWorker implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(AuthMailWorker.name);
  private timer?: NodeJS.Timeout;
  private running?: Promise<void>;

  constructor(
    @Inject(AUTH_REPOSITORY) private readonly repository: AuthRepository,
    private readonly crypto: AuthCrypto,
    @Inject(EMAIL_SENDER) private readonly sender: EmailSender,
  ) {}

  onApplicationBootstrap(): void {
    this.timer = setInterval(() => {
      void this.flush();
    }, 5000);
    this.timer.unref();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    await this.running;
  }

  flush(): Promise<void> {
    if (this.running) return this.running;
    this.running = this.deliver().finally(() => {
      this.running = undefined;
    });
    return this.running;
  }

  private async deliver(): Promise<void> {
    try {
      await this.repository.cleanup();
      for (let i = 0; i < 10; i++) {
        const job = await this.repository.claimMail();
        if (!job) return;
        try {
          const token = this.crypto.decrypt(job.encryptedToken);
          const verify = job.purpose === 'verify_email';
          await this.sender.send({
            deliveryId: job.id,
            to: job.email,
            subject: verify
              ? 'Freeva — Xác thực email'
              : 'Freeva — Đặt lại mật khẩu',
            text: `${verify ? 'Mã xác thực email (hiệu lực tối đa 24 giờ)' : 'Mã đặt lại mật khẩu (hiệu lực tối đa 30 phút)'}:\n\n${token}\n\nNhập mã trong ứng dụng Freeva. Nếu không yêu cầu, hãy bỏ qua email này.`,
          });
          await this.repository.completeMail(job.id);
        } catch {
          // Claim lease retries after one minute until expiry. No SMTP exception/PII in logs.
          this.logger.warn('Auth email delivery failed; retry scheduled');
        }
      }
    } catch {
      this.logger.warn('Auth mail storage unavailable; retry scheduled');
    }
  }
}
