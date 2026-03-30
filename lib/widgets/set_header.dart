import 'package:flutter/material.dart';

class SetHeader extends StatelessWidget {
  final String title;
  final String setCode;
  final double progress;
  final int owned;
  final int total;
  final bool isExpanded;
  final Color themeColor;
  final VoidCallback onTap;

  const SetHeader({
    super.key,
    required this.title,
    required this.setCode,
    required this.progress,
    required this.owned,
    required this.total,
    required this.isExpanded,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90.0,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: Text("$title ($setCode)",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87))),
                Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: isExpanded ? themeColor : Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            color: themeColor,
                            minHeight: 8))),
                const SizedBox(width: 12),
                Text("$owned / $total",
                    style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
