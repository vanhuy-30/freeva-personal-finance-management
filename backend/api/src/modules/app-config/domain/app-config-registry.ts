import { DEFAULT_ALERT_THRESHOLDS } from '../../budgets/domain/budget';
import { MAX_RATE_BPS } from '../../loans/domain/loan';
import { MAX_INSTALLMENTS, MIN_INSTALLMENTS } from '../../card-installments/domain/card-installment';
import { FORECAST_DEFAULT_MONTHS, FORECAST_MAX_MONTHS } from '../../forecast/domain/forecast';
import { GOAL_KINDS } from '../../goals/domain/goal';
import {
  CARD_HIGH_USAGE_THRESHOLD,
  CARD_NEAR_LIMIT_THRESHOLD,
  DEFAULT_DAILY_LOG_TIME,
  DEFAULT_QUIET_END,
  DEFAULT_QUIET_START,
} from '../../notifications/domain/notification';
import { MAX_RANGE_DAYS, SERIES_WINDOWS } from '../../reports/domain/report';
import { IMPORT_MAX_ROWS } from '../../transaction-import/domain/transaction-import';
import { CSV_EXPORT_MAX_ROWS } from '../../transactions/domain/csv-export';
import { CATEGORY_ICONS } from '../../categories/domain/category';
import { DEFAULT_COMMON_MERCHANTS } from '../../category-suggestions/domain/suggest';
import type { ConfigDefinition, ConfigValue, FlagDefinition } from './app-config';

/**
 * BE-P5-E08: every server flag and config key. Defaults equal what the app and API use today
 * (audit in tasks/phase-05.md, BE-P5-001), so an empty database changes nothing. Keys that are
 * technical limits (row caps, column sizes) can only be lowered: their max is the current value.
 * Add a key here, then read it in the app and API in the same task.
 */
export const FLAG_DEFINITIONS = {
  category_suggest: { description: 'Gợi ý danh mục khi ghi chi và nhập CSV (BE-P5-E03).' },
  insights: { description: 'Thẻ insight trên Tổng quan và màn phân tích (BE-P5-E04).' },
  forecast: { description: 'Dự báo chi cuối tháng, ngày đạt mục tiêu và what-if (BE-P5-E06, BE-P5-E07).' },
  google_sign_in: { description: 'Đăng nhập bằng Google trên app (đang hiện "Sắp có").' },
  apple_sign_in: { description: 'Đăng nhập bằng Apple trên app (đang hiện "Sắp có").' },
  profile_edit: { description: 'Sửa hồ sơ ở màn Cá nhân (đang hiện "Sắp có").' },
} as const satisfies Record<string, FlagDefinition>;

export type FlagKey = keyof typeof FLAG_DEFINITIONS;

export const CONFIG_DEFINITIONS = {
  'budget.alertThresholdOptions': {
    type: 'integer_list', default: [70, 80, 90, 100], min: 1, max: 100, minItems: 1, maxItems: 10,
    description: 'Các mốc % cho chọn ở "Báo khi đã dùng" của ngân sách.',
  },
  'budget.defaultAlertThresholds': {
    type: 'integer_list', default: DEFAULT_ALERT_THRESHOLDS, min: 1, max: 100, minItems: 1, maxItems: 4,
    description: 'Mốc cảnh báo mặc định khi tạo ngân sách và ở gợi ý ngân sách lúc onboarding.',
  },
  'budget.maxAlertThresholds': {
    type: 'integer', default: 4, min: 1, max: 4,
    description: 'Số mốc cảnh báo tối đa trên một ngân sách.',
  },
  'forecast.monthOptions': {
    type: 'integer_list', default: [3, 6, 12], min: 1, max: FORECAST_MAX_MONTHS, minItems: 1, maxItems: 6,
    description: 'Số tháng cho chọn ở màn dự báo số dư.',
  },
  'forecast.defaultMonths': {
    type: 'integer', default: FORECAST_DEFAULT_MONTHS, min: 1, max: FORECAST_MAX_MONTHS,
    description: 'Số tháng mặc định khi mở màn dự báo số dư.',
  },
  'installment.termOptions': {
    type: 'integer_list', default: [3, 6, 9, 12], min: MIN_INSTALLMENTS, max: MAX_INSTALLMENTS, minItems: 1, maxItems: 8,
    description: 'Kỳ hạn trả góp thẻ cho chọn nhanh (tháng).',
  },
  'installment.defaultTerm': {
    type: 'integer', default: 6, min: MIN_INSTALLMENTS, max: MAX_INSTALLMENTS,
    description: 'Kỳ hạn trả góp chọn sẵn (tháng).',
  },
  'recurring.remindBeforeOptions': {
    type: 'integer_list', default: [0, 1, 3, 7], min: 0, max: 30, minItems: 1, maxItems: 8,
    description: 'Số ngày nhắc trước cho chọn ở khoản định kỳ.',
  },
  'recurring.defaultRemindBefore': {
    type: 'integer', default: 3, min: 0, max: 30,
    description: 'Số ngày nhắc trước mặc định của khoản định kỳ mới.',
  },
  'creditCard.highUsagePercent': {
    type: 'integer', default: CARD_HIGH_USAGE_THRESHOLD, min: 1, max: 100,
    description: 'Mức dùng hạn mức thẻ (%) bắt đầu coi là cao.',
  },
  'creditCard.criticalUsagePercent': {
    type: 'integer', default: CARD_NEAR_LIMIT_THRESHOLD, min: 1, max: 100,
    description: 'Mức dùng hạn mức thẻ (%) coi là sắp chạm hạn mức.',
  },
  'creditCard.dueSoonDays': {
    type: 'integer', default: 7, min: 1, max: 31,
    description: 'Còn bao nhiêu ngày tới hạn thanh toán thẻ thì hiện "Sắp đến hạn".',
  },
  'debt.dueSoonDays': {
    type: 'integer', default: 14, min: 1, max: 90,
    description: 'Còn bao nhiêu ngày tới hạn cho mượn / đi mượn thì hiện "Sắp đến hạn".',
  },
  'onboarding.incomeSuggestionsVnd': {
    type: 'money_minor_list', default: ['10000000', '15000000', '25000000', '40000000'], currencyCode: 'VND',
    minItems: 0, maxItems: 6,
    description: 'Mức thu nhập gợi ý chọn nhanh ở câu hỏi onboarding (VND).',
  },
  'onboarding.savingsSharePercent': {
    type: 'integer', default: 20, min: 0, max: 100,
    description: 'Phần trăm thu nhập dành để tiết kiệm trong gợi ý ngân sách lúc onboarding.',
  },
  'onboarding.maxGoals': {
    type: 'integer', default: 2, min: 1, max: 2,
    description: 'Số mục tiêu tối đa chọn ở câu hỏi onboarding.',
  },
  'onboarding.goalKinds': {
    type: 'enum_list', default: ['emergency', 'home', 'car', 'travel', 'education', 'wedding', 'custom'],
    values: GOAL_KINDS, minItems: 1, maxItems: GOAL_KINDS.length,
    description: 'Loại mục tiêu tiết kiệm cho chọn ở onboarding, theo thứ tự hiện.',
  },
  'notification.dailyLogDefaultTime': {
    type: 'time', default: DEFAULT_DAILY_LOG_TIME,
    description: 'Giờ nhắc ghi chi chọn sẵn khi user bật nhắc.',
  },
  'notification.quietStartDefault': {
    type: 'time', default: DEFAULT_QUIET_START,
    description: 'Giờ bắt đầu giờ yên lặng mặc định.',
  },
  'notification.quietEndDefault': {
    type: 'time', default: DEFAULT_QUIET_END,
    description: 'Giờ kết thúc giờ yên lặng mặc định.',
  },
  'notification.minuteStep': {
    type: 'integer', default: 15, min: 1, max: 60,
    description: 'Bước phút trên bánh xe chọn giờ nhắc.',
  },
  'netWorth.defaultWindow': {
    type: 'enum', default: '6m', values: SERIES_WINDOWS,
    description: 'Khoảng thời gian mặc định của biểu đồ tài sản ròng.',
  },
  'investment.chartDefaultWindow': {
    type: 'enum', default: '6m', values: SERIES_WINDOWS,
    description: 'Khoảng thời gian mặc định của biểu đồ đầu tư.',
  },
  'report.topRows': {
    type: 'integer', default: 3, min: 1, max: 10,
    description: 'Số danh mục hiện riêng trước dòng "Khác" ở báo cáo và Tổng quan.',
  },
  'home.recentTransactions': {
    type: 'integer', default: 3, min: 1, max: 10,
    description: 'Số giao dịch gần đây trên Tổng quan.',
  },
  'goal.defaultDateOffsetDays': {
    type: 'integer', default: 30, min: 1, max: 3650,
    description: 'Ngày đạt mục tiêu chọn sẵn: hôm nay cộng số ngày này.',
  },
  'goal.maxDateOffsetYears': {
    type: 'integer', default: 60, min: 1, max: 100,
    description: 'Ngày đạt mục tiêu xa nhất cho chọn (năm kể từ hôm nay).',
  },
  'security.pinMaxAttempts': {
    type: 'integer', default: 5, min: 3, max: 10,
    description: 'Số lần nhập sai PIN trước khi đăng xuất.',
  },
  'password.minLength': {
    type: 'integer', default: 8, min: 8, max: 64,
    description: 'Độ dài mật khẩu tối thiểu.',
  },
  'password.veryStrongLength': {
    type: 'integer', default: 16, min: 8, max: 128,
    description: 'Độ dài để thanh độ mạnh mật khẩu báo "rất mạnh" khi không có ký hiệu.',
  },
  'profile.displayNameMaxLength': {
    type: 'integer', default: 60, min: 1, max: 60,
    description: 'Độ dài tối đa tên hiển thị.',
  },
  'import.maxRows': {
    type: 'integer', default: IMPORT_MAX_ROWS, min: 1, max: IMPORT_MAX_ROWS,
    description: 'Số dòng tối đa một lần nhập CSV.',
  },
  'categorySuggest.minConfidencePercent': {
    type: 'integer', default: 60, min: 50, max: 100,
    description: 'Gợi ý danh mục theo lịch sử chỉ hiện khi danh mục dùng nhiều nhất chiếm ít nhất bấy nhiêu % các lần trước (BE-P5-E03).',
  },
  'categorySuggest.historySize': {
    type: 'integer', default: 50, min: 5, max: 200,
    description: 'Số giao dịch gần nhất cùng cửa hàng (hoặc cùng ghi chú) được xét khi gợi ý danh mục.',
  },
  'categorySuggest.commonMerchants': {
    type: 'pair_list', default: DEFAULT_COMMON_MERCHANTS, values: CATEGORY_ICONS, minItems: 0, maxItems: 500, maxTextLength: 60,
    description: 'Cửa hàng chung và icon danh mục gợi ý, mỗi mục "Tên: icon" (vd. "Grab: transport"). Dùng khi user chưa có lịch sử ở cửa hàng đó.',
  },
  'export.csvMaxRows': {
    type: 'integer', default: CSV_EXPORT_MAX_ROWS, min: 1, max: CSV_EXPORT_MAX_ROWS,
    description: 'Số dòng tối đa một lần xuất CSV.',
  },
  'transaction.maxTags': {
    type: 'integer', default: 20, min: 0, max: 20,
    description: 'Số nhãn tối đa trên một giao dịch.',
  },
  // Technical limits the API enforces as is (`editable: false`): the app reads them, staff cannot edit.
  'limit.passwordMaxLength': { type: 'integer', default: 128, min: 128, max: 128, editable: false, description: 'Độ dài mật khẩu tối đa.' },
  'limit.emailMaxLength': { type: 'integer', default: 254, min: 254, max: 254, editable: false, description: 'Độ dài email tối đa.' },
  'limit.walletNameMaxLength': { type: 'integer', default: 100, min: 100, max: 100, editable: false, description: 'Độ dài tên ví tối đa.' },
  'limit.categoryNameMaxLength': { type: 'integer', default: 100, min: 100, max: 100, editable: false, description: 'Độ dài tên danh mục tối đa.' },
  'limit.tagNameMaxLength': { type: 'integer', default: 100, min: 100, max: 100, editable: false, description: 'Độ dài tên nhãn tối đa.' },
  'limit.goalNameMaxLength': { type: 'integer', default: 80, min: 80, max: 80, editable: false, description: 'Độ dài tên mục tiêu tối đa.' },
  'limit.loanNameMaxLength': { type: 'integer', default: 80, min: 80, max: 80, editable: false, description: 'Độ dài tên khoản vay tối đa.' },
  'limit.recurringNameMaxLength': { type: 'integer', default: 80, min: 80, max: 80, editable: false, description: 'Độ dài tên khoản định kỳ tối đa.' },
  'limit.investmentNameMaxLength': { type: 'integer', default: 80, min: 80, max: 80, editable: false, description: 'Độ dài tên khoản đầu tư tối đa.' },
  'limit.debtNameMaxLength': { type: 'integer', default: 80, min: 80, max: 80, editable: false, description: 'Độ dài tên người mượn / cho mượn tối đa.' },
  'limit.transactionNoteMaxLength': { type: 'integer', default: 2000, min: 2000, max: 2000, editable: false, description: 'Độ dài ghi chú giao dịch tối đa.' },
  'limit.merchantMaxLength': { type: 'integer', default: 200, min: 200, max: 200, editable: false, description: 'Độ dài tên nơi chi tối đa.' },
  'limit.noteMaxLength': { type: 'integer', default: 500, min: 500, max: 500, editable: false, description: 'Độ dài ghi chú của khoản đầu tư, cho mượn / đi mượn tối đa.' },
  'limit.feedbackMaxLength': { type: 'integer', default: 2000, min: 2000, max: 2000, editable: false, description: 'Độ dài góp ý tối đa.' },
  'limit.periodStartDayMax': { type: 'integer', default: 28, min: 28, max: 28, editable: false, description: 'Ngày bắt đầu kỳ, ngày sao kê, ngày đến hạn thẻ lớn nhất.' },
  'limit.budgetThresholdMax': { type: 'integer', default: 100, min: 100, max: 100, editable: false, description: 'Mốc cảnh báo ngân sách lớn nhất (%).' },
  'limit.forecastMaxMonths': { type: 'integer', default: FORECAST_MAX_MONTHS, min: FORECAST_MAX_MONTHS, max: FORECAST_MAX_MONTHS, editable: false, description: 'Số tháng dự báo số dư lớn nhất.' },
  'limit.installmentMinTerm': { type: 'integer', default: MIN_INSTALLMENTS, min: MIN_INSTALLMENTS, max: MIN_INSTALLMENTS, editable: false, description: 'Kỳ hạn trả góp nhỏ nhất.' },
  'limit.installmentMaxTerm': { type: 'integer', default: MAX_INSTALLMENTS, min: MAX_INSTALLMENTS, max: MAX_INSTALLMENTS, editable: false, description: 'Kỳ hạn trả góp lớn nhất.' },
  'limit.remindBeforeMax': { type: 'integer', default: 30, min: 30, max: 30, editable: false, description: 'Số ngày nhắc trước lớn nhất.' },
  'limit.recurringIntervalMax': { type: 'integer', default: 366, min: 366, max: 366, editable: false, description: 'Khoảng lặp lớn nhất của khoản định kỳ.' },
  'limit.loanRateMaxBps': { type: 'integer', default: MAX_RATE_BPS, min: MAX_RATE_BPS, max: MAX_RATE_BPS, editable: false, description: 'Lãi suất lớn nhất (phần vạn / năm).' },
  'limit.reportMaxRangeDays': { type: 'integer', default: MAX_RANGE_DAYS, min: MAX_RANGE_DAYS, max: MAX_RANGE_DAYS, editable: false, description: 'Khoảng báo cáo dài nhất (ngày).' },
  'limit.importMaxChars': { type: 'integer', default: 1_000_000, min: 1_000_000, max: 1_000_000, editable: false, description: 'Số ký tự tối đa của một file CSV nhập.' },
} as const satisfies Record<string, ConfigDefinition>;

export type ConfigKey = keyof typeof CONFIG_DEFINITIONS;

type Widen<D> = D extends { type: 'integer' }
  ? number
  : D extends { type: 'integer_list' }
    ? readonly number[]
    : D extends { type: 'money_minor_list' | 'enum_list' | 'pair_list' }
      ? readonly string[]
      : string;

/** Typed effective value of a key, e.g. `number` for `budget.maxAlertThresholds`. */
export type ConfigValueOf<K extends ConfigKey> = Widen<(typeof CONFIG_DEFINITIONS)[K]>;

/**
 * Rules across keys, checked on the values that would be live after a staff edit.
 * Returns the reason when the set does not hold together, else null.
 */
export function crossCheckConfig(values: Record<ConfigKey, ConfigValue>): string | null {
  const v = <K extends ConfigKey>(key: K) => values[key] as ConfigValueOf<K>;
  if ((v('budget.defaultAlertThresholds')).length > v('budget.maxAlertThresholds')) {
    return 'budget.defaultAlertThresholds has more items than budget.maxAlertThresholds';
  }
  if (!v('forecast.monthOptions').includes(v('forecast.defaultMonths'))) {
    return 'forecast.defaultMonths must be one of forecast.monthOptions';
  }
  if (!v('installment.termOptions').includes(v('installment.defaultTerm'))) {
    return 'installment.defaultTerm must be one of installment.termOptions';
  }
  if (!v('recurring.remindBeforeOptions').includes(v('recurring.defaultRemindBefore'))) {
    return 'recurring.defaultRemindBefore must be one of recurring.remindBeforeOptions';
  }
  if (v('creditCard.highUsagePercent') >= v('creditCard.criticalUsagePercent')) {
    return 'creditCard.highUsagePercent must be below creditCard.criticalUsagePercent';
  }
  if (v('password.veryStrongLength') < v('password.minLength')) {
    return 'password.veryStrongLength must be at least password.minLength';
  }
  return null;
}

export function isFlagKey(key: string): key is FlagKey {
  return Object.prototype.hasOwnProperty.call(FLAG_DEFINITIONS, key);
}

export function isConfigKey(key: string): key is ConfigKey {
  return Object.prototype.hasOwnProperty.call(CONFIG_DEFINITIONS, key);
}
