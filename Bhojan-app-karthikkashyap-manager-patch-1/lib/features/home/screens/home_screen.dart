import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Version Update Banner Placeholder
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.white),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'A newer version is available..',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        minimumSize: const Size(80, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Update'),
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Empty space where products would go
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Center(
                  child: Text(
                    'Products & Content Layout\n(Module 2)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 16,
      toolbarHeight: 70,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Your Location:', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600)),
              Row(
                children: [
                  Text('Capgemini B2', style: AppTextStyles.labelLarge.copyWith(fontSize: 18)),
                  const Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, color: AppColors.primary),
            Text('Search', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600, fontSize: 10)),
          ],
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => context.push('/profile'), // Direct profile access from top right
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, color: AppColors.primary),
              Text('Profile', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600, fontSize: 10)),
            ],
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);
        // Navigate to profile if "More" (index 4) is tapped
        if (index == 4) {
          context.push('/profile');
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Colors.grey.shade600,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: [
        const BottomNavigationBarItem(
          icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.receipt_long)),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Padding(padding: const EdgeInsets.only(bottom: 4), child: Icon(Icons.groups_outlined, color: Colors.grey.shade600)),
          label: 'Social Distancing',
        ),
        const BottomNavigationBarItem(
          icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.shopping_basket_outlined)),
          label: 'Cart',
        ),
        const BottomNavigationBarItem(
          icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.menu)),
          label: 'More',
        ),
      ],
    );
  }
}
