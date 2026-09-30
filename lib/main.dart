import 'package:flutter/material.dart';

import 'pages.dart';
import 'state.dart';

const mint = Color(0xFFC5CCF2);
const lilac = Color(0xFFCDB8E8);
const peach = Color(0xFFFFD3B8);
const sky = Color(0xFFB8D8F0);
const rose = Color(0xFFF7C6D4);
const cream = Color(0xFFFAF7F2);
const ink = Color(0xFF3B3A4A);

void main() {
  runApp(const GymFlowApp());
}

class GymFlowApp extends StatelessWidget {
  const GymFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: lilac,
          brightness: Brightness.light,
          surface: cream,
        ).copyWith(
          primary: const Color(0xFF7E6BB0),
          secondary: const Color(0xFF7E6BB0),
        );
    return MaterialApp(
      title: 'GymFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: cream,
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: cream,
          foregroundColor: ink,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final state = AppState();
  int index = 0;

  static const destinations = [
    (Icons.home_rounded, 'Início'),
    (Icons.fitness_center_rounded, 'Equipamentos'),
    (Icons.auto_awesome_rounded, 'IA'),
    (Icons.list_alt_rounded, 'Treinos'),
    (Icons.menu_book_rounded, 'Exercícios'),
    (Icons.show_chart_rounded, 'Progresso'),
  ];

  @override
  void initState() {
    super.initState();
    gifLookup = state.gifFor;
    altLookup = state.alternativesFor;
    altExercise = state.exerciseForAlt;
    state.init();
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  void go(int i) => setState(() => index = i);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final pages = <Widget>[
          HomePage(state: state, go: go),
          EquipmentPage(state: state, go: go),
          AiPage(state: state, go: go),
          WorkoutsPage(state: state, go: go),
          CatalogPage(state: state),
          ProgressPage(state: state),
        ];
        final Widget body = state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.error!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: state.retry,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              )
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: pages[index],
                ),
              );
        final wide = MediaQuery.sizeOf(context).width >= 800;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: index,
                  onDestinationSelected: go,
                  labelType: NavigationRailLabelType.all,
                  indicatorColor: lilac,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'GymFlow',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: ink,
                      ),
                    ),
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.$1),
                        label: Text(d.$2),
                      ),
                  ],
                ),
                Expanded(child: SafeArea(child: body)),
              ],
            ),
          );
        }
        return Scaffold(
          body: SafeArea(child: body),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: go,
            backgroundColor: Colors.white,
            indicatorColor: lilac,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
            destinations: [
              for (final d in destinations)
                NavigationDestination(icon: Icon(d.$1), label: d.$2),
            ],
          ),
        );
      },
    );
  }
}
