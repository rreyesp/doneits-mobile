import 'package:flutter/material.dart';
import 'package:vikunja_app/core/theming/app_colors.dart';
import 'package:vikunja_app/core/utils/priority.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';

class PriorityBatch extends StatelessWidget {
  final int priority;

  const PriorityBatch(this.priority, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);

    if (color == Colors.transparent) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: Icon(
          Icons.push_pin,
          size: 14,
          color: color,
        ),
      ),
    );
  }

  Color _priorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFBDBDBD);
      case 2:
        return Colors.orange;
      case 3:
      case 4:
      case 5:
        return Colors.red;
      default:
        return Colors.transparent;
    }
  }
}