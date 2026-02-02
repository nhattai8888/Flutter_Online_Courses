import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  void _navigateTo(BuildContext context, String path) {
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey[400],
      showSelectedLabels: true,
      showUnselectedLabels: true,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.school_outlined),
          activeIcon: const Icon(Icons.school),
          label: 'Học',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.mic_outlined),
          activeIcon: const Icon(Icons.mic),
          label: 'Nói',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.refresh_outlined),
          activeIcon: const Icon(Icons.refresh),
          label: 'Ôn tập',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: 'Cá nhân',
        ),
      ],
      onTap: (index) {
        final paths = ['/home', '/learning', '/speaking', '/review', '/profile'];
        _navigateTo(context, paths[index]);
      },
    );
  }
}
