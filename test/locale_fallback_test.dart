import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = AppLocalizations.supportedLocales;

  Locale resolve(List<Locale> preferred) =>
      basicLocaleListResolution(preferred, supported);

  test('English is the fallback for languages the app does not ship', () {
    expect(supported.first, const Locale('en'));
    for (final code in ['nl', 'pl', 'sv', 'ar', 'tr']) {
      expect(resolve([Locale(code)]), const Locale('en'), reason: code);
    }
  });

  test('shipped languages still resolve to themselves', () {
    expect(resolve([const Locale('de', 'DE')]), const Locale('de'));
    expect(resolve([const Locale('pt', 'BR')]), const Locale('pt'));
    expect(resolve([const Locale('ja')]), const Locale('ja'));
  });
}
