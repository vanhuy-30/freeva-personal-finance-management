export type PushLocale = 'vi' | 'en';

export type PushCopyInput = {
  titleKey: string;
  bodyKey: string;
  params: Record<string, string | number>;
};

type Copy = { title: string; body: string };

const GENERIC: Record<PushLocale, Copy> = {
  vi: { title: 'Freeva', body: 'Bạn có thông báo mới.' },
  en: { title: 'Freeva', body: 'You have a new notification.' },
};

function param(params: Record<string, string | number>, key: string): string {
  return String(params[key] ?? '');
}

/** Same wording as the in-app inbox (apps/mobile app_*.arb notifyInbox*). Only non-sensitive params are used. */
export function pushCopy(locale: string, input: PushCopyInput): Copy {
  const lang: PushLocale = locale.toLowerCase().startsWith('en') ? 'en' : 'vi';
  const { titleKey, params } = input;
  const days = Number(params.days ?? 0);
  switch (titleKey) {
    case 'budget_threshold':
      return lang === 'vi'
        ? { title: `Ngân sách đã chạm ${param(params, 'threshold')}%`, body: `Bạn đã dùng đến ${param(params, 'threshold')}% hạn mức tháng này.` }
        : { title: `Budget reached ${param(params, 'threshold')}%`, body: `You have used ${param(params, 'threshold')}% of this month's budget.` };
    case 'recurring_soon':
      return lang === 'vi'
        ? { title: 'Định kỳ sắp chạy', body: `Một giao dịch định kỳ chạy vào ${param(params, 'executionDate')}.` }
        : { title: 'Recurring about to run', body: `A recurring transaction runs on ${param(params, 'executionDate')}.` };
    case 'card_due': {
      const vi = days <= 0 ? 'Thẻ đến hạn hôm nay.' : `Thẻ đến hạn trong ${days} ngày.`;
      const en = days <= 0 ? 'A card is due today.' : `A card is due in ${days} day${days === 1 ? '' : 's'}.`;
      return lang === 'vi' ? { title: 'Thẻ sắp đến hạn', body: vi } : { title: 'Card due soon', body: en };
    }
    case 'card_high_debt':
      return lang === 'vi'
        ? { title: 'Dư nợ thẻ cao', body: `Bạn đã dùng ${param(params, 'threshold')}% hạn mức thẻ.` }
        : { title: 'High card balance', body: `You have used ${param(params, 'threshold')}% of a card limit.` };
    case 'card_near_limit':
      return lang === 'vi'
        ? { title: 'Thẻ sắp vượt hạn mức', body: `Bạn đã dùng ${param(params, 'threshold')}% hạn mức thẻ.` }
        : { title: 'Card near its limit', body: `You have used ${param(params, 'threshold')}% of a card limit.` };
    default:
      return GENERIC[lang];
  }
}
