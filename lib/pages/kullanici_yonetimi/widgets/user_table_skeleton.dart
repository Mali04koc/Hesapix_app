import 'package:flutter/material.dart';
import 'package:hesapix_app/theme/hesapix_colors.dart';

class UserTableSkeleton extends StatelessWidget {
  const UserTableSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _box(height: 16),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _box(height: 14),
              ),
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
