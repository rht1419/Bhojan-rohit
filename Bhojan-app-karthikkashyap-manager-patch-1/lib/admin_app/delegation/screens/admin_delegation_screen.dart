import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminDelegationScreen extends StatefulWidget {
  const AdminDelegationScreen({super.key});

  @override
  State<AdminDelegationScreen> createState() => _AdminDelegationScreenState();
}

class _AdminDelegationScreenState extends State<AdminDelegationScreen> {
  final _searchController = TextEditingController();
  String? _selectedUser = 'Priya S';
  
  final Map<String, bool> _modules = {
    'Auth': true,
    'Orders': true,
    'Logs': true,
    'Vendors': false,
    'Config': false,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Text('Delegate Access', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Select Admin User
            Text('1. Select Admin User', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                  if (_selectedUser != null) ...[
                    const SizedBox(height: 16),
                    InputChip(
                      avatar: const CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5')), // Placeholder
                      label: Text(_selectedUser!),
                      labelStyle: const TextStyle(color: Colors.white),
                      backgroundColor: AppColors.primary,
                      deleteIconColor: Colors.white,
                      onDeleted: () => setState(() => _selectedUser = null),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 2. Select Modules
            Text('2. Select Modules', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: _modules.keys.map((module) {
                  return Column(
                    children: [
                      SwitchListTile(
                        title: Text(module, style: AppTextStyles.bodyLarge),
                        value: _modules[module]!,
                        onChanged: (val) => setState(() => _modules[module] = val),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.blue.shade600,
                      ),
                      if (module != _modules.keys.last) const Divider(height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // 3. Set Expiry
            Text('3. Set Expiry', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Oct 24, 2023 11:59 PM', style: AppTextStyles.bodyLarge),
                  const Icon(Icons.calendar_today, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Grant Access Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Grant Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 48),

            // Active Delegations
            Text('ACTIVE DELEGATIONS', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600, letterSpacing: 1)),
            const SizedBox(height: 16),
            _buildDelegationCard('Amit Patel', 'Orders, Logs', 'Expires in 2 days', 'https://i.pravatar.cc/100?img=11'),
            const SizedBox(height: 12),
            _buildDelegationCard('Rohan Kumar', 'Auth, Vendors', 'Expires in 14 days', null, 'RK'),
          ],
        ),
      ),
    );
  }

  Widget _buildDelegationCard(String name, String modules, String expiry, String? avatarUrl, [String? initials]) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.teal.shade100,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Text(initials ?? '', style: TextStyle(color: Colors.teal.shade900)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$modules • $expiry', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text('Revoke', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
