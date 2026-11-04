import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'state/app_dependencies.dart';
import 'state/theme_cubit.dart';
import 'ui/shell/app_shell.dart';

class GymFlowApp extends StatefulWidget {
  const GymFlowApp({super.key});

  @override
  State<GymFlowApp> createState() => _GymFlowAppState();
}

class _GymFlowAppState extends State<GymFlowApp> {
  late final Future<AppDependencies> _deps = AppDependencies.create();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _deps,
      builder: (context, snap) {
        if (!snap.hasData) return _Boot(error: snap.error);
        return snap.data!.provide(child: const _ThemedApp());
      },
    );
  }
}

class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (_, mode) => MaterialApp(
        title: 'GymFlow',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: mode,
        home: const AppShell(),
      ),
    );
  }
}

/// Tela exibida enquanto o app carrega (ou se falhar ao iniciar).
class _Boot extends StatelessWidget {
  final Object? error;
  const _Boot({this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.dark),
      home: Scaffold(
        body: Center(
          child: error == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Erro ao iniciar o GymFlow: $error'),
                ),
        ),
      ),
    );
  }
}
