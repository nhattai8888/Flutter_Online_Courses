import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'bottom_nav_bar.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShellScreen({
    super.key,
    required this.child,
    required this.location,
  });

  int _getSelectedIndex() {
    final paths = [ '/curriculum', '/speaking', '/review', '/profile'];
    int index = paths.indexWhere((path) => location.startsWith(path));
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _getSelectedIndex(),
      ),
    );
  }
}
