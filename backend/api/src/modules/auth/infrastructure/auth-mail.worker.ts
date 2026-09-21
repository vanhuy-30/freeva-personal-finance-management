import {
  Inject,
  Injectable,
  Logger,
  OnModuleDestroy,
  OnApplicationBootstrap,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, type Transporter } from 'nodemailer';
import {
  AUTH_REPOSITORY,
  type AuthRepository,
} from '../domain/auth.repository';
import { AuthCrypto } from './auth-crypto';

@Injectable()
export class AuthMailWorker implements OnApplicationBootstrap, OnModuleDestroy {
  private readonly logger = new Logger(AuthMailWorker.name);
  private readonly transport: Transporter;
  private readonly from: string;
  private timer?: NodeJS.Timeout;
  private running?: Promise<void>;

  constructor(
    @Inject(AUTH_REPOSITORY) private readonly repository: AuthRepository,
    private readonly crypto: AuthCrypto,
    config: ConfigService,
  ) {
    const local = ['development', 'test'].includes(
      config.get<string>('NODE_ENV') ?? '',
    );
    const host = config.get<string>('SMTP_HOST');
    const from = config.get<string>('SMTP_FROM');
    if (!host || !from) throw new Error('SMTP_HOST and SMTP_FROM are required');
    this.from = from;
    const port = Number(config.get<string>('SMTP_PORT') ?? '587');
    if (!Number.isInteger(port) || port < 1 || port > 65535)
      throw new Error('Invalid SMTP_PORT');
    const user = config.get<string>('SMTP_USER');
    const pass = config.get<string>('SMTP_PASSWORD');
    if (Boolean(user) !== Boolean(pass))
      throw new Error(
        'SMTP_USER and SMTP_PASSWORD must be configured together',
      );
    this.transport = createTransport({
      host,
      port,
      secure: port === 465,
      requireTLS: !local,
      auth: user ? { user, pass } : undefined,
      connectionTimeout: 10_000,
      greetingTimeout: 10_000,
      socketTimeout: 15_000,
      logger: false,
      debug: false,
      disableFileAccess: true,
      disableUrlAccess: true,
    });
  }

  onApplicationBootstrap(): void {
    this.timer = setInterval(() => {
      void this.flush();
    }, 5000);
    this.timer.unref();
  }

  async onModuleDestroy(): Promise<void> {
    if (this.timer) clearInterval(this.timer);
    await this.running;
    this.transport.close();
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
          await this.transport.sendMail({
            from: this.from,
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
