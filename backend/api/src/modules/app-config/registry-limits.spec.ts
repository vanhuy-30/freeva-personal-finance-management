import 'reflect-metadata';
import { getMetadataStorage } from 'class-validator';
import { NewCredentialsDto, EmailDto } from '../auth/dto/auth.dto';
import { CreateCategoryDto } from '../categories/category.dto';
import { CreateFeedbackDto } from '../feedback/feedback.dto';
import { CreateAccountDto } from '../financial-accounts/financial-account.dto';
import { CreateGoalDto } from '../goals/goal.dto';
import { CreateInvestmentDto } from '../investments/investment.dto';
import { CreateLoanDto } from '../loans/loan.dto';
import { CreatePersonalDebtDto } from '../personal-debts/personal-debt.dto';
import { UpdateProfileDto } from '../profile/profile.dto';
import { CreateRecurringDto } from '../recurring/recurring.dto';
import { CreateTagDto } from '../tags/tag.dto';
import { PreviewImportDto } from '../transaction-import/transaction-import.dto';
import { CreateTransactionDto } from '../transactions/transaction.dto';
import { CONFIG_DEFINITIONS, type ConfigKey } from './domain/app-config-registry';

/** Upper bound a class-validator decorator puts on a DTO property. */
function upperBound(dto: abstract new () => unknown, property: string, kind: 'length' | 'value'): number {
  const rules = getMetadataStorage()
    .getTargetValidationMetadatas(dto as new () => unknown, '', true, false)
    .filter((meta) => meta.propertyName === property);
  for (const rule of rules) {
    const name = rule.name ?? rule.type;
    const constraints = rule.constraints ?? [];
    if (kind === 'length' && name === 'maxLength') return constraints[0] as number;
    if (kind === 'length' && name === 'isLength') return constraints[1] as number;
    if (kind === 'value' && name === 'max') return constraints[0] as number;
  }
  throw new Error(`no ${kind} bound on ${dto.name}.${property}`);
}

/**
 * BE-P5-001: read-only `limit.*` keys repeat DTO decorators so the app can read them.
 * This keeps the two from drifting: change a decorator and this test names the key to update.
 */
const sources: [ConfigKey, abstract new () => unknown, string, 'length' | 'value'][] = [
  ['limit.passwordMaxLength', NewCredentialsDto, 'password', 'length'],
  ['limit.emailMaxLength', EmailDto, 'email', 'length'],
  ['limit.walletNameMaxLength', CreateAccountDto, 'name', 'length'],
  ['limit.categoryNameMaxLength', CreateCategoryDto, 'name', 'length'],
  ['limit.tagNameMaxLength', CreateTagDto, 'name', 'length'],
  ['limit.goalNameMaxLength', CreateGoalDto, 'name', 'length'],
  ['limit.loanNameMaxLength', CreateLoanDto, 'name', 'length'],
  ['limit.recurringNameMaxLength', CreateRecurringDto, 'name', 'length'],
  ['limit.investmentNameMaxLength', CreateInvestmentDto, 'name', 'length'],
  ['limit.debtNameMaxLength', CreatePersonalDebtDto, 'counterparty', 'length'],
  ['limit.transactionNoteMaxLength', CreateTransactionDto, 'notes', 'length'],
  ['limit.merchantMaxLength', CreateTransactionDto, 'merchant', 'length'],
  ['limit.noteMaxLength', CreatePersonalDebtDto, 'note', 'length'],
  ['limit.feedbackMaxLength', CreateFeedbackDto, 'message', 'length'],
  ['limit.periodStartDayMax', UpdateProfileDto, 'fiscalMonthStartDay', 'value'],
  ['limit.remindBeforeMax', CreateRecurringDto, 'remindDaysBefore', 'value'],
  ['limit.recurringIntervalMax', CreateRecurringDto, 'interval', 'value'],
  ['limit.loanRateMaxBps', CreateLoanDto, 'interestRateBps', 'value'],
  ['limit.importMaxChars', PreviewImportDto, 'text', 'length'],
  ['profile.displayNameMaxLength', UpdateProfileDto, 'displayName', 'length'],
];

describe('BE-P5-001 read-only limits match the DTOs', () => {
  it.each(sources)('%s', (key, dto, property, kind) => {
    expect(CONFIG_DEFINITIONS[key].default).toBe(upperBound(dto, property, kind));
  });

  it('marks every limit.* key read-only', () => {
    for (const [key, definition] of Object.entries(CONFIG_DEFINITIONS)) {
      if (key.startsWith('limit.')) expect((definition as { editable?: false }).editable).toBe(false);
    }
  });
});
