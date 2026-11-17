import 'package:flutter/widgets.dart';
import 'package:mobile/core/theme/lucide_icons.g.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/text/vietnamese_fold.dart';

/// A screen of the app that search can open (MOB-P6-001).
class AppFeature {
  const AppFeature(this.icon, this.route, this.label, this.keywords);

  final IconData icon;
  final String route;
  final String Function(S) label;

  /// Other words people type for it, without accents: "mat khau", "export".
  final List<String> keywords;
}

/// What the search box can open besides transactions. Order is the order of
/// the results, and of the shortcuts shown before anything is typed.
final appFeatures = <AppFeature>[
  AppFeature(LucideIcons.wallet, '/wallets', (s) => s.walletTitle, [
    'vi',
    'tai khoan',
    'ngan hang',
    'the',
    'wallet',
    'account',
  ]),
  AppFeature(LucideIcons.layoutGrid, '/categories', (s) => s.meCategories, [
    'danh muc',
    'category',
  ]),
  AppFeature(LucideIcons.tag, '/me/tags', (s) => s.meTags, ['nhan', 'tag']),
  AppFeature(LucideIcons.pieChart, '/budgets', (s) => s.budgetTitle, [
    'han muc',
    'budget',
  ]),
  AppFeature(LucideIcons.target, '/me/goals', (s) => s.goalsHomeTitle, [
    'tiet kiem',
    'goal',
    'saving',
  ]),
  AppFeature(LucideIcons.barChart3, '/reports', (s) => s.reportTitle, [
    'thong ke',
    'bieu do',
    'report',
  ]),
  AppFeature(
    LucideIcons.clipboardCheck,
    '/reports/month-review',
    (s) => s.monthReviewTitle,
    ['tong ket', 'review'],
  ),
  AppFeature(LucideIcons.repeat, '/me/recurring', (s) => s.recurringTitle, [
    'hoa don',
    'dinh ky',
    'bill',
    'recurring',
    'subscription',
  ]),
  AppFeature(LucideIcons.calendar, '/me/calendar', (s) => s.calendarTitle, [
    'lich',
    'calendar',
  ]),
  AppFeature(LucideIcons.handCoins, '/me/debts', (s) => s.txDebtTitle, [
    'no',
    'vay',
    'muon',
    'khoan vay',
    'debt',
    'loan',
  ]),
  AppFeature(
    LucideIcons.trendingUp,
    '/me/investments',
    (s) => s.investmentsTitle,
    ['co phieu', 'dau tu', 'investment', 'stock'],
  ),
  AppFeature(LucideIcons.landmark, '/me/net-worth', (s) => s.netWorthTitle, [
    'tai san',
    'net worth',
  ]),
  AppFeature(LucideIcons.lightbulb, '/insights', (s) => s.insightsTitle, [
    'phan tich',
    'insight',
  ]),
  AppFeature(LucideIcons.bell, '/me/notifications', (s) => s.meNotifications, [
    'nhac',
    'thong bao',
    'notification',
    'reminder',
  ]),
  AppFeature(
    LucideIcons.sparkles,
    '/me/auto-suggest',
    (s) => s.autoSuggestTitle,
    ['goi y', 'suggest'],
  ),
  AppFeature(LucideIcons.shieldCheck, '/me/security', (s) => s.meSecurity, [
    'bao mat',
    'security',
  ]),
  AppFeature(LucideIcons.lock, '/me/security/pin', (s) => s.meChangePinTitle, [
    'pin',
    'ma pin',
    'khoa',
    'mo khoa',
  ]),
  AppFeature(
    LucideIcons.keyRound,
    '/me/security/password',
    (s) => s.meChangePasswordTitle,
    ['mat khau', 'password'],
  ),
  AppFeature(LucideIcons.upload, '/me/export', (s) => s.meExportData, [
    'xuat',
    'sao luu',
    'csv',
    'export',
    'backup',
  ]),
  AppFeature(LucideIcons.download, '/me/import', (s) => s.meImportData, [
    'nhap',
    'import',
    'app khac',
  ]),
  AppFeature(LucideIcons.coins, '/me/money', (s) => s.meMoneyTitle, [
    'thu nhap',
    'ky tinh',
    'tien te',
    'income',
    'currency',
  ]),
  AppFeature(LucideIcons.user, '/profile', (s) => s.meProfileTitle, [
    'tai khoan',
    'ho so',
    'profile',
  ]),
  AppFeature(LucideIcons.refreshCw, '/sync', (s) => s.syncTitle, [
    'dong bo',
    'sync',
  ]),
  AppFeature(
    LucideIcons.trash,
    '/transactions/deleted',
    (s) => s.txTrashTitle,
    ['thung rac', 'da xoa', 'trash', 'deleted'],
  ),
  AppFeature(LucideIcons.helpCircle, '/help/faq', (s) => s.meFaq, [
    'tro giup',
    'huong dan',
    'help',
    'faq',
  ]),
  AppFeature(LucideIcons.messageSquare, '/help/feedback', (s) => s.meFeedback, [
    'gop y',
    'phan hoi',
    'feedback',
  ]),
];

/// The features matching [query] (accent-insensitive; the title or a keyword
/// contains it), at most [limit]. Empty for a blank query.
List<AppFeature> matchFeatures(S s, String query, {int limit = 5}) {
  final q = foldVietnamese(query.trim());
  if (q.isEmpty) return const [];
  final byLabel = <AppFeature>[];
  final byKeyword = <AppFeature>[];
  for (final f in appFeatures) {
    if (foldVietnamese(f.label(s)).contains(q)) {
      byLabel.add(f);
    } else if (q.length >= 2 && f.keywords.any((k) => k.contains(q))) {
      byKeyword.add(f);
    }
  }
  return [...byLabel, ...byKeyword].take(limit).toList();
}

/// Shortcuts shown before anything is typed.
List<AppFeature> quickFeatures() => [
  for (final route in const [
    '/wallets',
    '/categories',
    '/budgets',
    '/reports',
    '/me/export',
    '/me/security',
  ])
    appFeatures.firstWhere((f) => f.route == route),
];
