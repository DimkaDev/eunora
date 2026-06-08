import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:eunora/core/utils/animation_system.dart';
import '../providers/triggers_provider.dart';

class AddCustomTriggerModal extends ConsumerStatefulWidget {
  const AddCustomTriggerModal({super.key});

  @override
  ConsumerState<AddCustomTriggerModal> createState() => _AddCustomTriggerModalState();
}

class _AddCustomTriggerModalState extends ConsumerState<AddCustomTriggerModal> {
  final _nameController = TextEditingController();
  String _selectedCategory = 'Lifestyle & Habits';
  bool _isSaving = false;

  final List<String> _categories = ['Lifestyle & Habits', 'Diet & Nutrition', 'Emotional & Environmental'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(triggersProvider.notifier).addCustomTrigger(_nameController.text, _selectedCategory);
      context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0C4BC).withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add your own trigger',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Noto Serif',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B1A),
            ),
          ),
          const SizedBox(height: 32),
          
          // Trigger Name
          const Text(
            'Trigger name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4D453F),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g., Spicy foods',
              hintStyle: TextStyle(color: const Color(0xFF7F756E).withOpacity(0.6)),
              filled: true,
              fillColor: const Color(0xFFF2EDEA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(32),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          
          // Category
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4D453F),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Bounceable(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEDDDF5) : const Color(0xFFEDE7E5),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF6C6074) : const Color(0xFF4D453F),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          Bounceable(
            onTap: _isSaving ? null : _handleSave,
            child: IgnorePointer(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF67594E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  elevation: 0,
                ),
                child: _isSaving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save trigger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Bounceable(
            onTap: () => context.pop(),
            child: IgnorePointer(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFF67594E).withOpacity(0.2), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF67594E)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
