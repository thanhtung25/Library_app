import 'package:flutter/material.dart';
import 'package:library_app/model/book_model.dart';

import '../../../../model/author_model.dart';

class CartBookCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;
  final Future<AuthorModel> authorFuture;

  const CartBookCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
    required this.authorFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        children: [
          // ── Radio circle ──
          GestureDetector(
            onTap: onSelect,
            child: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.4),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: 12, height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // ── Cover image ──
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imagePath.startsWith('http')
                ? Image.network(
              imagePath,
              width: 46, height: 62, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : Image.asset(
              imagePath.isEmpty
                  ? 'assets/images/book_placeholder.png'
                  : imagePath,
              width: 46, height: 62, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
          ),
          const SizedBox(width: 12),

          // ── Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<AuthorModel>(
                  future: authorFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Text('Đang tải...');
                    }
                    if (snap.hasError || !snap.hasData) {
                      return const Text('Không có tác giả');
                    }
                    return Text(
                      snap.data!.full_name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xffE5835E),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Срок бронирования: 3 дня',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          // ── Delete ──
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 24, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 46, height: 62,
    color: Colors.grey.shade300,
    child: const Icon(Icons.book, size: 24),
  );
}