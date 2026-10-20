import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { TAG_REPOSITORY } from './domain/tag.repository';
import { PrismaTagRepository } from './infrastructure/prisma-tag.repository';
import { TagController } from './tag.controller';
import { TagService } from './tag.service';
@Module({
  imports: [AuthModule],
  controllers: [TagController],
  providers: [TagService, { provide: TAG_REPOSITORY, useClass: PrismaTagRepository }],
})
export class TagModule {}
