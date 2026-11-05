import { pushCopy } from './push-copy';

describe('BE-P3-006 daily_log push copy', () => {
  const input = { titleKey: 'daily_log', bodyKey: 'daily_log_body', params: {} };

  it('speaks Vietnamese by default and English for en locales', () => {
    expect(pushCopy('vi', input).title).toBe('Ghi chi hôm nay');
    expect(pushCopy('en-US', input).title).toBe('Log today');
  });
});

describe('BE-P3-007 debt push copy', () => {
  it('names the direction and the days, never the person or amount', () => {
    const due = { titleKey: 'debt_due', bodyKey: 'debt_due_body', params: { direction: 'lent', days: 2, debtId: 'x', dueDate: '2026-11-04' } };
    expect(pushCopy('vi', due)).toEqual({ title: 'Sắp đến hạn thu nợ', body: 'Một khoản cho mượn đến hạn trong 2 ngày.' });
    expect(pushCopy('en', { ...due, params: { ...due.params, direction: 'borrowed', days: 0 } }).body).toBe('A debt you owe is due today.');
    const late = { titleKey: 'debt_overdue', bodyKey: 'debt_overdue_body', params: { direction: 'borrowed', days: 3 } };
    expect(pushCopy('vi', late).title).toBe('Khoản đi mượn quá hạn');
  });
});
