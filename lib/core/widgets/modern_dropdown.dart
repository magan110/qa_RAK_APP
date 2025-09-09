import 'package:flutter/material.dart';

class ModernDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> items;
  final Function(String?) onChanged;
  final Duration delay;
  final bool isRequired;
  final String? value;

  const ModernDropdown({
    Key? key,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.delay = Duration.zero,
    this.isRequired = true,
    this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        dropdownColor: Colors.white,
        decoration: InputDecoration(
          labelText: isRequired ? '$label *' : label,
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: onChanged,
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Please select $label';
          }
          return null;
        },
        items: items.map((item) {
          return DropdownMenuItem<String>(value: item, child: Text(item));
        }).toList(),
      ),
    );
  }
}
