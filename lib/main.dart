import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import 'app_config.dart';
import 'screens/import_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/swipe_screen.dart';
import 'services/storage.dart';
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
  final store = LocalStore();
  await store.init();
  final state = AppState(store)..restore();
  runApp(SwipeSpendApp(state: state));
}

class SwipeSpendApp extends StatelessWidget {
  const SwipeSpendApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        initialRoute: state.onboardingDone ? ImportScreen.route : OnboardingScreen.route,
        onGenerateRoute: (settings) {
          final Widget page = switch (settings.name) {
            ImportScreen.route => const ImportScreen(),
            SwipeScreen.route => const SwipeScreen(),
            SummaryScreen.route => const SummaryScreen(),
            _ => const OnboardingScreen(),
          };
          return PageRouteBuilder(
            settings: settings,
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, _, _) => page,
            transitionsBuilder: (_, anim, _, child) {
              final a = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
              return FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
                  child: child,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
