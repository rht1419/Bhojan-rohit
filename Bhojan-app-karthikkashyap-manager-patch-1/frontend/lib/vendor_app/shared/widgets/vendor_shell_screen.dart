import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class VendorShellScreen extends StatelessWidget {
  final Widget child;

  const VendorShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Determine current index based on the route
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/vendor/dashboard')) currentIndex = 0;
    if (location.startsWith('/vendor/search')) currentIndex = 1;
    if (location.startsWith('/vendor/profile')) currentIndex = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == 0) context.go('/vendor/dashboard');
            if (index == 1) context.go('/vendor/search'); // Placeholder for search
            if (index == 2) context.go('/vendor/profile');
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_filled)),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.search)),
              label: 'SEARCH',
            ),
            BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person)),
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}
