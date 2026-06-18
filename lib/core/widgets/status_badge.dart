import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';

enum StatusType {
  pending,
  accepted,
  rejected,
  sessionCreated,
  started,
  awaitingPayment,
  completed,
  paid,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  StatusType get _type {
    switch (status.toLowerCase()) {
      case 'accepted':
        return StatusType.accepted;
      case 'rejected':
        return StatusType.rejected;
      case 'session_created':
        return StatusType.sessionCreated;
      case 'started':
        return StatusType.started;
      case 'awaiting_payment':
        return StatusType.awaitingPayment;
      case 'completed':
        return StatusType.completed;
      case 'paid':
        return StatusType.paid;
      default:
        return StatusType.pending;
    }
  }

  Color get _bg {
    switch (_type) {
      case StatusType.accepted:
        return AppTheme.success.withAlpha(30);
      case StatusType.rejected:
        return AppTheme.danger.withAlpha(30);
      case StatusType.sessionCreated:
        return const Color(0xFFFF9800).withAlpha(30);
      case StatusType.started:
        return AppTheme.primary.withAlpha(30);
      case StatusType.awaitingPayment:
        return AppTheme.warning.withAlpha(30);
      case StatusType.completed:
        return AppTheme.secondary.withAlpha(30);
      case StatusType.paid:
        return const Color(0xFFFFD700).withAlpha(30);
      default:
        return AppTheme.warning.withAlpha(30);
    }
  }

  Color get _fg {
    switch (_type) {
      case StatusType.accepted:
        return AppTheme.success;
      case StatusType.rejected:
        return AppTheme.danger;
      case StatusType.sessionCreated:
        return const Color(0xFFFF9800);
      case StatusType.started:
        return AppTheme.primary;
      case StatusType.awaitingPayment:
        return AppTheme.warning;
      case StatusType.completed:
        return AppTheme.secondary;
      case StatusType.paid:
        return const Color(0xFFFFD700);
      default:
        return AppTheme.warning;
    }
  }

  IconData get _icon {
    switch (_type) {
      case StatusType.accepted:
        return Icons.check_circle_outline;
      case StatusType.rejected:
        return Icons.cancel_outlined;
      case StatusType.sessionCreated:
        return Icons.key_outlined;
      case StatusType.started:
        return Icons.play_circle_outline;
      case StatusType.awaitingPayment:
        return Icons.payments_outlined;
      case StatusType.completed:
        return Icons.task_alt;
      case StatusType.paid:
        return Icons.currency_rupee;
      default:
        return Icons.schedule;
    }
  }

  String get _label {
    switch (_type) {
      case StatusType.sessionCreated:
        return 'OTP READY';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _fg.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: _fg),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: _fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
