import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { GOAL_REPOSITORY } from './domain/goal.repository';
import { GoalController } from './goal.controller';
import { GoalService } from './goal.service';
import { PrismaGoalRepository } from './infrastructure/prisma-goal.repository';

@Module({
  imports: [AuthModule],
  controllers: [GoalController],
  providers: [GoalService, { provide: GOAL_REPOSITORY, useClass: PrismaGoalRepository }],
  exports: [GoalService],
})
export class GoalModule {}
