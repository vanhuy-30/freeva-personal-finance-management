import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/money/currency_catalog.dart';
import '../../../../core/widgets/freeva_sheet.dart';
import '../../../../core/widgets/freeva_toast.dart';
import '../../../profile/domain/declared_income.dart';
import '../../../profile/presentation/viewmodels/profile_view_model.dart';
import '../../../profile/presentation/widgets/income_band_list.dart';
import '../../../server_config/domain/app_limits.dart';

/// Edits the declared income band (Cá nhân), the same list as first-run
/// question 2: a tap saves the band, "Không muốn chia sẻ" clears it. Saved
/// through `PUT /profile/declared-income`.
Future<void> showIncomeSheet(BuildContext context, ProfileViewModel profile) {
  final s = S.of(context);
  return showFreevaSheet<void>(
    context: context,
    title: s.meIncome,
    builder: (context) => _IncomeBody(profile: profile),
  );
}

class _IncomeBody extends StatefulWidget {
  const _IncomeBody({required this.profile});

  final ProfileViewModel profile;

  @override
  State<_IncomeBody> createState() => _IncomeBodyState();
}

class _IncomeBodyState extends State<_IncomeBody> {
  bool _saving = false;

  String get _currency =>
      widget.profile.saved?.currency ?? CurrencyCatalog.current.defaultCode;

  Future<void> _save(DeclaredIncome? band) async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await widget.profile.saveDeclaredIncome(band);
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      showFreevaToast(context, message: S.of(context).meIncomeFailed);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saved = widget.profile.saved?.declaredIncome;
    final bands = incomeBandsFrom(
      getIt<AppLimitsSource>().requireLimits.onboardingIncomeBandsVnd,
    );
    return IncomeBandList(
      bands: bands,
      digits: CurrencyCatalog.current.digits(_currency),
      selected: saved,
      notShared: false,
      onBand: _save,
      onNotShared: () => _save(null),
    );
  }
}
