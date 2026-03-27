import 'package:flutter/material.dart';

class ShippingPaymentDialog extends StatelessWidget {
  final String address;
  final String phone;
  final double shippingFee;
  final String Function(double) formatCurrency;
  final VoidCallback onConfirm;

  const ShippingPaymentDialog({
    super.key,
    required this.address,
    required this.phone,
    required this.shippingFee,
    required this.formatCurrency,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF1EA),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.local_shipping_outlined,
              color: Color(0xffFF9E74), size: 22),
        ),
        const SizedBox(width: 12),
        const Text('Оплата доставки',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _row('Адрес', address),
              const SizedBox(height: 8),
              _row('Телефон', phone),
              const Divider(height: 20),
              _row(
                'Стоимость доставки',
                formatCurrency(shippingFee),
                valueColor: const Color(0xffFF9E74),
                bold: true,
              ),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline,
                  size: 16, color: Color(0xFF388E3C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Оплата производится при получении книги курьеру.',
                  style: TextStyle(
                      fontSize: 12.5, color: Colors.green.shade800),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Отмена',
              style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffFF9E74),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Подтвердить оплату',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _row(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}