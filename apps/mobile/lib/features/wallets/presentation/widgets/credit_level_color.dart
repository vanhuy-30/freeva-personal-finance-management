import 'package:flutter/material.dart';

import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.g.dart';
import '../../domain/credit_card_status.dart';

/// Limit bar colour by usage: < 70% data, 70–90% amber, > 90% red.
Color creditLevelColor(BuildContext context, CreditLevel level) =>
    switch (level) {
      CreditLevel.normal => context.colors.data1,
      CreditLevel.high => FreevaPrimitive.amber500,
      CreditLevel.critical => FreevaPrimitive.red500,
    };
