import 'package:flutter/material.dart';
import '../models/project_invite.dart';

class InviteStatusChip extends StatelessWidget {
  final InviteStatus status;
  const InviteStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case InviteStatus.pending:
        color = Colors.orange;
        break;
      case InviteStatus.accepted:
        color = Colors.green;
        break;
      case InviteStatus.rejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
