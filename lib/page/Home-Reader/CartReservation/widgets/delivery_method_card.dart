import 'package:flutter/material.dart';

class DeliveryMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const DeliveryMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1EA) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xffFF9E74) : Colors.black12,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? const Color(0xffFF9E74) : Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade700)),
                ],
              ),
            ),
            // ── Radio dot ──
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xffFF9E74)
                      : Colors.black54,
                  width: 1.4,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffFF9E74),
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}