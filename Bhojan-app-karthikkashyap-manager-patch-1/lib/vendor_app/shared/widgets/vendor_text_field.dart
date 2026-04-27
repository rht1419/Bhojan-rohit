import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class VendorTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final String? prefixText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool isValid;
  final bool isDropdown;
  final Widget? dropdownIcon;
  final VoidCallback? onTap;

  const VendorTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.prefixIcon,
    this.prefixText,
    this.validator,
    this.onChanged,
    this.isValid = false,
    this.isDropdown = false,
    this.dropdownIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: isDropdown,
            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 14),
              prefixIcon: prefixIcon,
              prefixText: prefixText,
              prefixStyle: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isValid)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
                    ),
                  if (isDropdown)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: dropdownIcon ?? const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
