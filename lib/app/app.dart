import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

class CollimaScopeApp extends ConsumerWidget {
  const CollimaScopeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final redMode = ref.watch(redModeProvider);
    return MaterialApp.router(
      title: 'CollimaScope',
      debugShowCheckedModeBanner: false,
      theme: redMode ? AppTheme.red() : AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
