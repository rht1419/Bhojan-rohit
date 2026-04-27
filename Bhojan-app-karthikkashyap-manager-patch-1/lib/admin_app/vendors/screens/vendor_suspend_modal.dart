import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class VendorSuspendModal extends StatefulWidget {
  final String vendorName;
  
  const VendorSuspendModal({super.key, required this.vendorName});

  @override
  State<VendorSuspendModal> createState() => _VendorSuspendModalState();
}

class _VendorSuspendModalState extends State<VendorSuspendModal> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 32),
            ),
            const SizedBox(height: 24),

            // Title & Description
            Text('Suspend Vendor?', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'This will immediately halt all operations and remove the vendor from the active listings. Are you sure?',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Reason Input
            Align(
              alignment: Alignment.centerLeft,
              child: Text('REASON FOR SUSPENSION', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600, letterSpacing: 1)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'e.g. Policy violation...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            ElevatedButton(
              onPressed: () {
                // Perform suspend logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vendor suspended successfully.'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935), // Red color from PNG
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Suspend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.primary, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
