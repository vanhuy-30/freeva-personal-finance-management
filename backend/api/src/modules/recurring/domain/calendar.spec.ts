import {
  addInterval, compareCalendar, dueDates, daysInMonth, formatCalendarParts, occurrencesInRange, parseCalendarParts,
} from './calendar';

describe('BE-P2-E01 recurring calendar', () => {
  it('rejects invalid calendar dates', () => {
    expect(() => parseCalendarParts('2026-02-30')).toThrow('VALIDATION_ERROR');
    expect(() => parseCalendarParts('2026-13-01')).toThrow('VALIDATION_ERROR');
    expect(() => parseCalendarParts('26-01-01')).toThrow('VALIDATION_ERROR');
  });

  it('clamps monthly recurrence when the month has no day 31', () => {
    expect(daysInMonth(2026, 2)).toBe(28);
    expect(daysInMonth(2024, 2)).toBe(29);
    expect(addInterval('2026-01-31', 'month', 1, 31)).toBe('2026-02-28');
    expect(addInterval('2026-02-28', 'month', 1, 31)).toBe('2026-03-31');
    expect(addInterval('2026-03-31', 'month', 1, 31)).toBe('2026-04-30');
    expect(addInterval('2024-01-31', 'month', 1, 31)).toBe('2024-02-29');
    expect(addInterval('2024-02-29', 'month', 1, 31)).toBe('2024-03-31');
  });

  it('advances day, week, year and custom intervals', () => {
    expect(addInterval('2026-01-15', 'day', 1, 15)).toBe('2026-01-16');
    expect(addInterval('2026-01-15', 'week', 1, 15)).toBe('2026-01-22');
    expect(addInterval('2026-01-15', 'week', 2, 15)).toBe('2026-01-29');
    expect(addInterval('2026-01-15', 'month', 3, 15)).toBe('2026-04-15');
    expect(addInterval('2024-02-29', 'year', 1, 29)).toBe('2025-02-28');
    expect(addInterval('2024-02-29', 'year', 4, 29)).toBe('2028-02-29');
  });

  it('lists due dates with end date and inactive skip', () => {
    expect(dueDates({
      nextExecutionDate: '2026-01-31',
      startDate: '2026-01-31',
      endDate: '2026-03-31',
      today: '2026-03-15',
      unit: 'month',
      interval: 1,
      active: true,
    })).toEqual(['2026-01-31', '2026-02-28']);

    expect(dueDates({
      nextExecutionDate: '2026-01-31',
      startDate: '2026-01-31',
      endDate: null,
      today: '2026-01-30',
      unit: 'month',
      interval: 1,
      active: true,
    })).toEqual([]);

    expect(dueDates({
      nextExecutionDate: '2026-01-01',
      startDate: '2026-01-01',
      endDate: null,
      today: '2026-01-05',
      unit: 'day',
      interval: 1,
      active: false,
    })).toEqual([]);
  });

  it('caps catch-up at the limit', () => {
    const dates = dueDates({
      nextExecutionDate: '2026-01-01',
      startDate: '2026-01-01',
      endDate: null,
      today: '2026-12-31',
      unit: 'day',
      interval: 1,
      active: true,
      limit: 10,
    });
    expect(dates).toHaveLength(10);
    expect(dates[0]).toBe('2026-01-01');
    expect(dates[9]).toBe('2026-01-10');
  });

  it('compares and formats calendar parts', () => {
    expect(compareCalendar('2026-01-01', '2026-01-02')).toBe(-1);
    expect(formatCalendarParts(2026, 1, 5)).toBe('2026-01-05');
  });

  it('projects occurrences inside a month from nextExecutionDate', () => {
    expect(occurrencesInRange({
      nextExecutionDate: '2026-01-31',
      startDate: '2026-01-31',
      endDate: null,
      rangeFrom: '2026-01-01',
      rangeTo: '2026-03-31',
      unit: 'month',
      interval: 1,
      active: true,
    })).toEqual(['2026-01-31', '2026-02-28', '2026-03-31']);

    expect(occurrencesInRange({
      nextExecutionDate: '2026-02-28',
      startDate: '2026-01-31',
      endDate: null,
      rangeFrom: '2026-01-01',
      rangeTo: '2026-03-31',
      unit: 'month',
      interval: 1,
      active: true,
    })).toEqual(['2026-02-28', '2026-03-31']);

    expect(occurrencesInRange({
      nextExecutionDate: '2026-01-15',
      startDate: '2026-01-15',
      endDate: '2026-01-20',
      rangeFrom: '2026-01-01',
      rangeTo: '2026-01-31',
      unit: 'day',
      interval: 1,
      active: true,
    })).toEqual(['2026-01-15', '2026-01-16', '2026-01-17', '2026-01-18', '2026-01-19', '2026-01-20']);

    expect(occurrencesInRange({
      nextExecutionDate: '2026-01-01',
      startDate: '2026-01-01',
      endDate: null,
      rangeFrom: '2026-01-01',
      rangeTo: '2026-01-31',
      unit: 'day',
      interval: 1,
      active: false,
    })).toEqual([]);
  });
});
