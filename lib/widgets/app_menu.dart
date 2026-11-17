import 'package:material_ui/material_ui.dart';

import '../app_config.dart';
import '../state/app_state.dart';
import '../theme.dart';

/// Menu met instellingen: onboarding opnieuw tonen, lokale data wissen.
class AppMenu extends StatelessWidget {
  const AppMenu({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      icon: Icon(Icons.more_horiz_rounded, color: onDark ? Colors.white : AppColors.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: (v) async {
        final state = AppScope.read(context);
        final nav = Navigator.of(context);
        final messenger = ScaffoldMessenger.of(context);
        switch (v) {
          case 'onboarding':
            await state.resetOnboarding();
            nav.pushNamedAndRemoveUntil('/', (r) => false);
          case 'wis':
            final ok = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Alles wissen?'),
                content: const Text(
                    'Je ingeladen uitgaven, swipes en notities op dit toestel worden gewist.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuleer')),
                  FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Wissen')),
                ],
              ),
            );
            if (ok == true) {
              await state.clearAll();
              nav.pushNamedAndRemoveUntil('/import', (r) => false);
              messenger.showSnackBar(const SnackBar(content: Text('Alles gewist.')));
            }
          case 'over':
            showAboutDialog(
              context: context,
              applicationName: AppConfig.appName,
              applicationVersion: 'demo v2',
              children: const [
                Text('Alles blijft lokaal in je browser of op je toestel. '
                    'Geen server, geen account.'),
              ],
            );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'onboarding', child: ListTile(leading: Icon(Icons.auto_stories_rounded), title: Text('Intro opnieuw tonen'))),
        PopupMenuItem(value: 'wis', child: ListTile(leading: Icon(Icons.delete_sweep_rounded), title: Text('Alle data wissen'))),
        PopupMenuItem(value: 'over', child: ListTile(leading: Icon(Icons.info_outline_rounded), title: Text('Over deze app'))),
      ],
    );
  }
}
