import 'package:material_ui/material_ui.dart';

import '../app_config.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/illustrations.dart';
import 'import_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const route = '/';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Step {
  const _Step(this.kicker, this.title, this.body);
  final String kicker;
  final String title;
  final String body;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _steps = [
    _Step(
      'STAP 1',
      'Je maand in een\npaar swipes',
      'Laad je uitgaven in (CSV of je Argenta-kredietkaart als pdf) en overloop ze één voor één. Snel, zonder Excel.',
    ),
    _Step(
      'STAP 2',
      'Rechts = opnieuw\nLinks = spijt',
      'Was het het waard? Swipe rechts. Liever niet meer? Swipe links. Eerlijk zijn, niemand kijkt mee.',
    ),
    _Step(
      'STAP 3',
      'Zie wat je\nkan besparen',
      'Meteen je spijt in euro, per categorie, en wat je per maand overhoudt als je dat schrapt.',
    ),
  ];

  Future<void> _finish() async {
    await AppScope.read(context).completeOnboarding();
    if (mounted) Navigator.of(context).pushReplacementNamed(ImportScreen.route);
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return Scaffold(
      backgroundColor: AppColors.night,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
                child: Row(
                  children: [
                    const AppLogo(onDark: true),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: last ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: TextButton(
                        onPressed: last ? null : _finish,
                        style: TextButton.styleFrom(foregroundColor: Colors.white70),
                        child: const Text('Overslaan'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: _steps.length,
                  onPageChanged: (p) => setState(() => _page = p),
                  itemBuilder: (context, i) => _StepView(step: _steps[i], index: i),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _steps.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _page ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.ink,
                  ),
                  onPressed: last
                      ? _finish
                      : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 380),
                            curve: Curves.easeOutCubic,
                          ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(last ? 'Aan de slag' : 'Volgende', key: ValueKey(last)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.index});
  final _Step step;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingIllustration(step: index),
          const SizedBox(height: 30),
          Text(step.kicker,
              style: const TextStyle(
                  color: Color(0xFF9FA2FF), fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 10),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.08,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.keep, AppColors.brand],
            ),
          ),
          child: const Icon(Icons.swipe_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Text(AppConfig.appName,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: -0.4,
              color: onDark ? Colors.white : AppColors.ink,
            )),
      ],
    );
  }
}
