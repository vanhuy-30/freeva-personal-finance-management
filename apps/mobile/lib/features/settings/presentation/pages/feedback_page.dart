import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';

import '../../../../core/router/nav_back.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/app_preferences.dart';
import '../viewmodels/settings_view_model.dart';
import '../widgets/feedback_kind_field.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final SettingsViewModel _model = getIt<SettingsViewModel>();
  final TextEditingController _message = TextEditingController();
  FeedbackKind _kind = FeedbackKind.idea;
  var _copied = false;
  var _invalid = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = _model.prepareFeedback(_kind, _message.text);
    if (text == null) {
      setState(() {
        _copied = false;
        _invalid = true;
      });
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() {
      _copied = true;
      _invalid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.feedbackTitle),
        leading: IconButton(
          tooltip: s.settingsBack,
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.popOrGo('/me'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.feedbackHelp),
              FeedbackKindField(
                kind: _kind,
                onChanged: (value) => setState(() => _kind = value),
              ),
              TextField(
                controller: _message,
                minLines: 4,
                maxLines: 8,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: s.feedbackMessage,
                  errorText: _invalid ? s.feedbackInvalid : null,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _copy, child: Text(s.feedbackCopy)),
              if (_copied) ...[
                const SizedBox(height: 12),
                Text(s.feedbackCopied),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
