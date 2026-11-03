import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        Card(child: SwitchListTile.adaptive(title: const Text('Dark appearance'), subtitle: const Text('Choose the SubZero dark theme.'), value: mode == ThemeMode.dark, onChanged: (value) => ref.read(themeModeProvider.notifier).state = value ? ThemeMode.dark : ThemeMode.light)),
        const Card(child: ListTile(leading: Icon(Icons.lock_outline), title: Text('Privacy first'), subtitle: Text('Your subscription list is stored locally on this device.'))),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('About SubZero'), subtitle: Text('Your subscriptions. Under control.'))),
        const Padding(padding: EdgeInsets.all(12), child: Text('SubZero tracks subscriptions but never processes payments or requests banking credentials.')),
      ]),
    );
  }
}
