import { Inject, Injectable } from '@nestjs/common';
import { minor } from '../transactions/domain/transaction';
import {
  goalStatus,
  incomeShareBps,
  monthsLeft,
  percentBps,
  presetOf,
  remainingMinor,
  requiredPerMonth,
  GOAL_PRESETS,
  type GoalRecord,
} from './domain/goal';
import { GOAL_REPOSITORY, type GoalContext, type GoalRepository } from './domain/goal.repository';
import type { AdjustGoalDto, CreateGoalDto, MoveGoalDto, UpdateGoalDto } from './goal.dto';

const text = (value: bigint) => value.toString();

function response(goal: GoalRecord, context: GoalContext) {
  const months = goal.targetDate === null ? null : monthsLeft(context.today, goal.targetDate);
  const required = requiredPerMonth(goal.targetMinor, goal.currentMinor, months);
  const share = incomeShareBps(required, context.monthlyIncomeMinor[goal.currencyCode] ?? null);
  return {
    id: goal.id,
    clientId: goal.clientId,
    kind: goal.kind,
    name: goal.name,
    currencyCode: goal.currencyCode,
    targetMinor: text(goal.targetMinor),
    currentMinor: text(goal.currentMinor),
    remainingMinor: text(remainingMinor(goal.targetMinor, goal.currentMinor)),
    percentBps: percentBps(goal.targetMinor, goal.currentMinor),
    targetDate: goal.targetDate,
    monthsLeft: months,
    requiredPerMonthMinor: required === null ? null : text(required),
    ...(share === null ? {} : { incomeShareBps: share }),
    monthlyContributionMinor: goal.monthlyContributionMinor === null ? null : text(goal.monthlyContributionMinor),
    status: goalStatus(goal.targetMinor, goal.currentMinor, goal.targetDate, context.today),
    accountId: goal.accountId,
    icon: goal.icon,
    colorToken: goal.colorToken,
    archivedAt: goal.archivedAt?.toISOString() ?? null,
    version: goal.version,
    createdAt: goal.createdAt.toISOString(),
    updatedAt: goal.updatedAt.toISOString(),
  };
}

@Injectable()
export class GoalService {
  constructor(@Inject(GOAL_REPOSITORY) private readonly repository: GoalRepository) {}

  presets() {
    return { items: GOAL_PRESETS.map(({ kind, icon, colorToken }) => ({ kind, icon, colorToken })) };
  }

  async list(userId: string, includeArchived = false) {
    const [goals, context] = await Promise.all([this.repository.list(userId, includeArchived), this.repository.context(userId)]);
    return { items: goals.map(goal => response(goal, context)) };
  }

  async find(userId: string, id: string) {
    const [goal, context] = await Promise.all([this.repository.find(userId, id), this.repository.context(userId)]);
    return response(goal, context);
  }

  async history(userId: string, id: string) {
    const items = await this.repository.history(userId, id);
    return {
      items: items.map(item => ({
        id: item.id,
        kind: item.kind,
        amountMinor: item.amountMinor === null ? null : text(item.amountMinor),
        transfer: item.transfer,
        occurredOn: item.occurredOn,
        createdAt: item.createdAt.toISOString(),
      })),
    };
  }

  async create(userId: string, dto: CreateGoalDto) {
    const preset = presetOf(dto.kind);
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      kind: dto.kind,
      name: dto.name,
      targetMinor: minor(dto.targetMinor),
      currentMinor: dto.currentMinor === undefined ? 0n : minor(dto.currentMinor),
      targetDate: dto.targetDate ?? null,
      accountId: dto.accountId,
      monthlyContributionMinor: dto.monthlyContributionMinor == null ? null : minor(dto.monthlyContributionMinor),
      icon: dto.icon ?? preset.icon,
      colorToken: dto.colorToken === undefined ? preset.colorToken : dto.colorToken,
    });
    return { goal: response(result.goal, await this.repository.context(userId)), created: result.created };
  }

  async update(userId: string, id: string, dto: UpdateGoalDto) {
    const goal = await this.repository.update(userId, id, {
      version: dto.version,
      kind: dto.kind,
      name: dto.name,
      targetMinor: dto.targetMinor === undefined ? undefined : minor(dto.targetMinor),
      targetDate: dto.targetDate,
      monthlyContributionMinor:
        dto.monthlyContributionMinor === undefined
          ? undefined
          : dto.monthlyContributionMinor === null
            ? null
            : minor(dto.monthlyContributionMinor),
      icon: dto.icon,
      colorToken: dto.colorToken,
    });
    return response(goal, await this.repository.context(userId));
  }

  archive(userId: string, id: string, version: number) {
    return this.repository.archive(userId, id, version);
  }

  async contribute(userId: string, id: string, dto: MoveGoalDto) {
    const result = await this.repository.contribute(userId, id, this.move(dto));
    return { goal: response(result.goal, await this.repository.context(userId)), created: result.created };
  }

  async withdraw(userId: string, id: string, dto: MoveGoalDto) {
    const result = await this.repository.withdraw(userId, id, this.move(dto));
    return { goal: response(result.goal, await this.repository.context(userId)), created: result.created };
  }

  async adjust(userId: string, id: string, dto: AdjustGoalDto) {
    const goal = await this.repository.adjust(userId, id, minor(dto.currentMinor), dto.version);
    return response(goal, await this.repository.context(userId));
  }

  private move(dto: MoveGoalDto) {
    return {
      clientId: dto.clientId,
      amountMinor: minor(dto.amountMinor),
      otherAccountId: dto.accountId ?? null,
      occurredOn: dto.occurredOn,
    };
  }
}
