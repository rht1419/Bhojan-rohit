import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/api/api_client.dart';
import '../services/admin_employee_service.dart';

final _employeeServiceProvider = Provider<AdminEmployeeService>((ref) => AdminEmployeeService(ApiClient()));

class AdminEmployeeOffboardScreen extends ConsumerStatefulWidget {
  const AdminEmployeeOffboardScreen({super.key});

  @override
  ConsumerState<AdminEmployeeOffboardScreen> createState() => _AdminEmployeeOffboardScreenState();
}

class _AdminEmployeeOffboardScreenState extends ConsumerState<AdminEmployeeOffboardScreen> {
  final _searchCtrl = TextEditingController();
  List<AdminEmployee> _employees = [];
  bool _loading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees({String? search}) async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final service = ref.read(_employeeServiceProvider);
      final results = await service.listEmployees(search: search);
      if (mounted) setState(() { _employees = results; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMsg = 'Failed to load employees.'; _loading = false; });
    }
  }

  void _showOffboardSheet(AdminEmployee employee) {
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        bool sheetLoading = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Offboard ${employee.fullName}?', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(employee.employeeId, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                const SizedBox(height: 6),
                Text(employee.email, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will revoke all sessions and remove this employee from the active roster.',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('REASON (REQUIRED)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. Resigned, Contract ended...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: sheetLoading ? null : () async {
                      if (reasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide a reason.'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      setSheetState(() { sheetLoading = true; });
                      try {
                        final service = ref.read(_employeeServiceProvider);
                        await service.offboardEmployee(employee.id, reasonCtrl.text.trim());
                        if (!mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Employee offboarded. All sessions revoked.'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        _loadEmployees(); // refresh
                      } on AdminEmployeeException catch (e) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.userMessage), backgroundColor: Colors.red),
                        );
                      } catch (_) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Something went wrong. Please try again.'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: sheetLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Confirm Offboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Offboard Employee', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, Employee ID, or email',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _loadEmployees();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (v) => _loadEmployees(search: v.trim()),
              onChanged: (v) {
                if (v.isEmpty) _loadEmployees();
              },
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _errorMsg != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadEmployees, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _employees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_outline, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text('No employees found', style: TextStyle(color: Colors.grey.shade500)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _employees.length,
                            itemBuilder: (ctx, i) {
                              final emp = _employees[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                    child: Text(
                                      emp.fullName.isNotEmpty ? emp.fullName[0].toUpperCase() : '?',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(emp.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ID: ${emp.employeeId}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      Text(emp.email, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                      if (emp.department != null)
                                        Text(emp.department!, style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  onTap: () => _showOffboardSheet(emp),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
