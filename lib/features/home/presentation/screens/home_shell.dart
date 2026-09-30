import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../destination/presentation/screens/destination_list_screen.dart';
import '../../../guide/presentation/screens/guide_list_screen.dart';
import '../../../tour/presentation/screens/tour_list_screen.dart';
import '../../../user/presentation/screens/profile_screen.dart';
import 'home_dashboard_screen.dart';

final homeTabIndexProvider = StateProvider<int>((ref) => 0);

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  static const _tabs = [
    HomeDashboardScreen(),
    DestinationListScreen(),
    TourListScreen(),
    GuideListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(homeTabIndexProvider);

    return Scaffold(
      // Built lazily (not IndexedStack) so inactive tabs don't fetch data
      // or keep off-screen widgets mounted; Riverpod's cached provider
      // state means switching back doesn't re-trigger network calls.
      body: _tabs[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(homeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Places',
          ),
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage_rounded),
            label: 'Tours',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Guides',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
