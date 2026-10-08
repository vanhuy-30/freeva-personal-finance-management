import { HttpException, Inject, Injectable } from '@nestjs/common';
import {
  PROFILE_REPOSITORY,
  type Profile,
  type ProfileRepository,
} from './domain/profile.repository';

function error(status: number, code: string) {
  return new HttpException(
    { error: { code, message: 'Profile request could not be completed' } },
    status,
  );
}

@Injectable()
export class ProfileService {
  constructor(
    @Inject(PROFILE_REPOSITORY) private readonly repository: ProfileRepository,
  ) {}

  async get(userId: string) {
    const profile = await this.repository.find(userId);
    if (!profile) throw error(401, 'SESSION_INVALID');
    return profile;
  }

  async options() {
    const intl = Intl as typeof Intl & {
      supportedValuesOf(key: string): string[];
    };
    return {
      currencies: await this.repository.currencies(),
      timezones: [
        ...new Set([
          'UTC',
          'Asia/Ho_Chi_Minh',
          ...intl.supportedValuesOf('timeZone'),
        ]),
      ].sort(),
    };
  }

  async update(userId: string, profile: Profile) {
    // Reject offsets and unknown zones; accept IANA aliases used by existing users.
    if (!/^(UTC|[A-Za-z_]+(?:\/[A-Za-z0-9_+\-]+)+)$/.test(profile.timezone)) {
      throw error(400, 'VALIDATION_ERROR');
    }
    try {
      new Intl.DateTimeFormat('en', { timeZone: profile.timezone });
    } catch {
      throw error(400, 'VALIDATION_ERROR');
    }
    const currencies = await this.repository.currencies();
    if (!currencies.some(c => c.code === profile.defaultCurrencyCode)) {
      throw error(400, 'VALIDATION_ERROR');
    }
    const saved = await this.repository.update(userId, profile);
    if (!saved) throw error(409, 'PROFILE_CONFLICT');
    return saved;
  }
}
