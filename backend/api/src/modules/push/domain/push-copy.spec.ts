import { pushCopy } from './push-copy';

describe('BE-P3-006 daily_log push copy', () => {
  const input = { titleKey: 'daily_log', bodyKey: 'daily_log_body', params: {} };

  it('speaks Vietnamese by default and English for en locales', () => {
    expect(pushCopy('vi', input).title).toBe('Ghi chi hôm nay');
    expect(pushCopy('en-US', input).title).toBe('Log today');
  });
});
