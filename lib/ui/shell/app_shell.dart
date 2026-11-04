import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text.dart';
import '../../state/catalog_cubit.dart';
import '../../state/nav_cubit.dart';
import '../../state/theme_cubit.dart';
import '../features/catalog/catalog_page.dart';
import '../features/equipment/equipment_page.dart';
import '../features/home/home_page.dart';
import '../features/progress/progress_page.dart';
import '../features/workouts/workouts_page.dart';
import '../widgets/backup_notice.dart';
import '../widgets/page_body.dart';
import 'app_drawer.dart';
import 'lazy_indexed_stack.dart';
import 'nav_destinations.dart';

const wideBreakpoint = 960.0;

/// Estrutura principal: barra superior (estilo site) em telas largas e
/// navegação inferior no celular.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CatalogCubit, CatalogState>(
      builder: (context, catalog) {
        if (catalog.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (catalog.error != null) return _LoadError(message: catalog.error!);
        return BlocBuilder<NavCubit, AppTab>(
          builder: (context, tab) {
            final body = LazyIndexedStack(
              index: tab.index,
              builders: [
                (_) => const HomePage(),
                (_) => const WorkoutsPage(),
                (_) => const EquipmentPage(),
                (_) => const CatalogPage(),
                (_) => const ProgressPage(),
              ],
            );
            final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
            return wide
                ? _WideLayout(tab: tab, body: body)
                : _NarrowLayout(tab: tab, body: body);
          },
        );
      },
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final AppTab tab;
  final Widget body;
  const _NarrowLayout({required this.tab, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const _MobileTopBar(),
            const BackupNotice(),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) =>
            context.read<NavCubit>().go(AppTab.values[i]),
        destinations: [
          for (final d in navDestinations)
            NavigationDestination(icon: Icon(d.$2), label: d.$3),
        ],
      ),
    );
  }
}

/// Barra fina do celular: logo e botão do menu sanduíche.
class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 0),
      child: Row(children: [const _Logo(), const Spacer(), const MenuButton()]),
    );
  }
}

/// Abre o menu sanduíche (configurações e contato).
class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Menu',
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => Scaffold.of(context).openEndDrawer(),
    );
  }
}

class _WideLayout extends StatelessWidget {
  final AppTab tab;
  final Widget body;
  const _WideLayout({required this.tab, required this.body});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Scaffold(
      endDrawer: const AppDrawer(),
      body: Column(
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: p.card,
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      const _Logo(),
                      const SizedBox(width: 28),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final d in navDestinations)
                                _NavTab(
                                  icon: d.$2,
                                  label: d.$3,
                                  selected: tab == d.$1,
                                  onTap: () =>
                                      context.read<NavCubit>().go(d.$1),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const ThemeToggle(),
                      const SizedBox(width: 4),
                      const MenuButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const BackupNotice(),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          // Sempre com a borda preta, igual à tela de carregamento.
          decoration: BoxDecoration(
            color: p.volt,
            shape: BoxShape.circle,
            border: Border.all(color: p.onVolt, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text('GYMFLOW', style: AppText.display(28)),
      ],
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? p.volt : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: selected ? p.onVolt : p.muted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? p.onVolt : p.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alterna entre tema claro e escuro.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton.outlined(
      tooltip: dark ? 'Tema claro' : 'Tema escuro',
      onPressed: () =>
          context.read<ThemeCubit>().toggle(Theme.of(context).brightness),
      icon: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  const _LoadError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: context.read<CatalogCubit>().load,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
