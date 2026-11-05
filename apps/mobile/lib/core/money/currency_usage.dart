/// Whether the user deals in two or more currencies. Rates, the display
/// currency and "≈" lines only make sense then (MOB-P3-004).
///
/// [codes] are the currencies of every wallet (archived ones too, their
/// transactions still exist) and of any totals the server returned.
bool usesMultipleCurrencies(Iterable<String> codes) =>
    codes.toSet().length >= 2;
