import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { FEEDBACK_REPOSITORY } from './domain/feedback';
import { FeedbackController } from './feedback.controller';
import { PrismaFeedbackRepository } from './infrastructure/prisma-feedback.repository';

@Module({
  imports: [AuthModule],
  controllers: [FeedbackController],
  providers: [{ provide: FEEDBACK_REPOSITORY, useClass: PrismaFeedbackRepository }],
})
export class FeedbackModule {}
