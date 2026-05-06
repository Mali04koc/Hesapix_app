import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class UserTableSkeleton extends StatelessWidget {
  const UserTableSkeleton({
    super.key,
    this.rows = 6,
    this.isNarrow = false,
  });

  final int rows;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    if (isNarrow) {
      return Column(
        children: List.generate(rows, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HesapixColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(width: 140, height: 16),
                    _box(width: 24, height: 24),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _box(width: 60, height: 20),
                    const SizedBox(width: 8),
                    _box(width: 60, height: 20),
                  ],
                ),
                const SizedBox(height: 12),
                _box(width: 180, height: 14),
              ],
            ),
          );
        }),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(rows, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                _box(width: 150, height: 16),
                const SizedBox(width: 16),
                _box(width: 150, height: 14),
                const SizedBox(width: 12),
                _box(width: 72, height: 24),
                const SizedBox(width: 12),
                _box(width: 72, height: 24),
                const SizedBox(width: 12),
                _box(width: 88, height: 14),
                const SizedBox(width: 12),
                _box(width: 88, height: 14),
                const SizedBox(width: 12),
                _box(width: 36, height: 36),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _box({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: HesapixColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
