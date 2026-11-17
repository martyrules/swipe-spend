import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'screens/import_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/swipe_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('nl_BE');
  Intl.defaultLocale = 'nl_BE';
  if (kIsWeb) {
    // Semantics aan op web: toegankelijker en testbaar met een headless browser.
    SemanticsBinding.instance.ensureSemantics();
  }
  runApp(SwipeSpendApp(state: AppState()));
}

class SwipeSpendApp extends StatelessWidget {
  const SwipeSpendApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Swipe Spend',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        initialRoute: OnboardingScreen.route,
        routes: {
          OnboardingScreen.route: (_) => const OnboardingScreen(),
          ImportScreen.route: (_) => const ImportScreen(),
          SwipeScreen.route: (_) => const SwipeScreen(),
          SummaryScreen.route: (_) => const SummaryScreen(),
        },
      ),
    );
  }
}
