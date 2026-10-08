import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { PROFILE_REPOSITORY } from './domain/profile.repository';
import { PrismaProfileRepository } from './infrastructure/prisma-profile.repository';
import { ProfileController } from './profile.controller';
import { ProfileService } from './profile.service';

@Module({
  imports: [AuthModule],
  controllers: [ProfileController],
  providers: [
    ProfileService,
    { provide: PROFILE_REPOSITORY, useClass: PrismaProfileRepository },
  ],
})
export class ProfileModule {}
