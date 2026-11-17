import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'import_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const route = '/';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Step {
  const _Step(this.icon, this.color, this.title, this.body);
  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  static const _steps = [
    _Step(
      Icons.receipt_long_rounded,
      AppColors.accent,
      'Je maand in een paar swipes',
      'Laad de uitgaven van deze maand in (CSV van je bank) en overloop ze één voor één. Snel, zonder Excel.',
    ),
    _Step(
      Icons.swipe_rounded,
      AppColors.keep,
      'Rechts = opnieuw\nLinks = spijt',
      'Was het het waard? Swipe rechts. Had je het beter niet gedaan? Swipe links. Eerlijk zijn, niemand kijkt mee.',
    ),
    _Step(
      Icons.savings_rounded,
      AppColors.regret,
      'Zie wat je kan besparen',
      'Je krijgt meteen te zien hoeveel spijt je deze maand had, per categorie, en wat je per maand overhoudt als je dat schrapt.',
    ),
  ];

  void _finish() =>
      Navigator.of(context).pushReplacementNamed(ImportScreen.route);

  @override
  Widget build(BuildContext context) {
    final last = _page == _steps.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  const _Logo(),
                  const Spacer(),
                  if (!last)
                    TextButton(onPressed: _finish, child: const Text('Overslaan')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _steps.length,
                onPageChanged: (p) => setState(() => _page = p),
                itemBuilder: (context, i) => _StepView(step: _steps[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _steps.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black12,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: FilledButton(
                onPressed: last
                    ? _finish
                    : () => _pages.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                child: Text(last ? 'Aan de slag' : 'Volgende'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});
  final _Step step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(56),
            ),
            child: Icon(step.icon, size: 92, color: step.color),
          ),
          const SizedBox(height: 40),
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900, height: 1.15),
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: Colors.black54, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.swipe_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text('Swipe Spend',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }
}
