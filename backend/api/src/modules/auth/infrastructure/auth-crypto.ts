import { Injectable, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  createCipheriv,
  createDecipheriv,
  createHash,
  createHmac,
  randomBytes,
} from 'node:crypto';
import * as argon2 from 'argon2';

@Injectable()
export class AuthCrypto implements OnModuleInit {
  private readonly key: Buffer;
  private dummyHash!: string;

  constructor(config: ConfigService) {
    const key = config.get<string>('AUTH_SECRET_KEY') ?? '';
    if (!/^[a-fA-F0-9]{64}$/.test(key)) {
      throw new Error('AUTH_SECRET_KEY must be a random 32-byte hex key');
    }
    this.key = Buffer.from(key, 'hex');
  }

  async onModuleInit(): Promise<void> {
    this.dummyHash = await this.hashPassword(randomBytes(32).toString('hex'));
  }

  hashPassword(password: string): Promise<string> {
    return argon2.hash(password, {
      type: argon2.argon2id,
      memoryCost: 19456,
      timeCost: 2,
      parallelism: 1,
    });
  }

  async verifyPassword(
    hash: string | null,
    password: string,
  ): Promise<boolean> {
    const valid = await argon2.verify(hash ?? this.dummyHash, password);
    return hash !== null && valid;
  }

  token(): string {
    return randomBytes(32).toString('hex');
  }
  digest(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
  rateKey(value: string): string {
    return createHmac('sha256', this.key).update(value).digest('hex');
  }

  encrypt(token: string): string {
    const iv = randomBytes(12);
    const cipher = createCipheriv('aes-256-gcm', this.key, iv);
    const ciphertext = Buffer.concat([
      cipher.update(token, 'utf8'),
      cipher.final(),
    ]);
    return Buffer.concat([iv, cipher.getAuthTag(), ciphertext]).toString(
      'base64',
    );
  }

  decrypt(value: string): string {
    const bytes = Buffer.from(value, 'base64');
    const decipher = createDecipheriv(
      'aes-256-gcm',
      this.key,
      bytes.subarray(0, 12),
    );
    decipher.setAuthTag(bytes.subarray(12, 28));
    return Buffer.concat([
      decipher.update(bytes.subarray(28)),
      decipher.final(),
    ]).toString('utf8');
  }
}
