import 'package:flutter/material.dart';

class CartSummary extends StatelessWidget {
  final int bookCount;
  final String deliveryMethod;
  final String pickupDate;
  final String pickupTime;
  final double shippingFee;
  final bool shippingPaid;
  final String Function(double) formatCurrency;

  const CartSummary({
    super.key,
    required this.bookCount,
    required this.deliveryMethod,
    required this.pickupDate,
    required this.pickupTime,
    required this.shippingFee,
    required this.shippingPaid,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Информация о бронировании',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _row('Количество книг', bookCount.toString()),
          _row('Способ получения',
              deliveryMethod == 'delivery' ? 'Доставка' : 'Самовывоз'),
          if (deliveryMethod == 'pickup') ...[
            _row('Дата получения', pickupDate),
            _row('Время', pickupTime),
          ],
          _row('Срок бронирования', '3 дня'),
          _row('Статус', 'Ожидает подтверждения'),
          if (deliveryMethod == 'delivery') ...[
            const Divider(height: 20, thickness: 1),
            _row('Стоимость доставки', formatCurrency(shippingFee)),
            _row('Итого к оплате', formatCurrency(shippingFee),
                highlight: true),
            if (shippingPaid)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF43A047), size: 16),
                  const SizedBox(width: 6),
                  Text('Оплата доставки подтверждена',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
          ],
        ],
      ),
    );
  }

  Widget _row(String title, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: TextStyle(
                  fontSize: highlight ? 15 : 14,
                  color: highlight ? Colors.black87 : Colors.grey.shade700,
                  fontWeight:
                  highlight ? FontWeight.w700 : FontWeight.normal,
                )),
          ),
          Text(value,
              style: TextStyle(
                fontSize: highlight ? 16 : 14,
                fontWeight: FontWeight.w700,
                color: highlight
                    ? const Color(0xffFF9E74)
                    : Colors.black87,
              )),
        ],
      ),
    );
  }
}