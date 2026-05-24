import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/models/other_medication.dart';

class OtherMedicationListItem extends StatelessWidget {
  final OtherMedication medication;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const OtherMedicationListItem({
    super.key,
    required this.medication,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(medication.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe Right -> Delete
          onDelete();
          return true;
        } else if (direction == DismissDirection.endToStart) {
          // Swipe Left -> Edit
          onEdit();
          return false; // Don't dismiss, just trigger edit
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF5F5F4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconData(medication.category),
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medication.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1D1B1A),
                    ),
                  ),
                  Text(
                    _buildDoseAndFrequency(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF78716C),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Color(0xFFA8A29E), size: 20),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFA8A29E), size: 20),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  String _buildDoseAndFrequency() {
    final dosePart = medication.dose?.isNotEmpty == true ? medication.dose : null;
    final freqPart = medication.frequency?.isNotEmpty == true ? medication.frequency : null;
    if (dosePart != null && freqPart != null) {
      return '$dosePart • $freqPart';
    }
    return dosePart ?? freqPart ?? '';
  }

  IconData _getIconData(String? category) {
    switch (category) {
      case 'Vitamins': return Icons.spa;
      case 'Minerals': return Icons.eco;
      case 'Herbal': return Icons.nature;
      case 'Prescription': return Icons.medical_services;
      default: return Icons.medication;
    }
  }
}
