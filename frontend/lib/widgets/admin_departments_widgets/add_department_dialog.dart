import 'package:flutter/material.dart';
import '../app_theme.dart'; // ADD

class AddDepartmentDialog extends StatefulWidget {
  final Future<void> Function(String name) onAdd;
  const AddDepartmentDialog({super.key, required this.onAdd});

  @override
  State<AddDepartmentDialog> createState() => _AddDepartmentDialogState();
}

class _AddDepartmentDialogState extends State<AddDepartmentDialog> {
  final _modalCtrl = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _modalCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _modalCtrl.text.trim();
    if (name.isEmpty || _adding) return;
    setState(() => _adding = true);
    await widget.onAdd(name);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkInternTheme;
    final activeColor = isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);
    final bgColor = isDark ? const Color(0xFF0D0D2B) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade500;
    final inputFill = isDark ? const Color(0xFF1A1A3A) : const Color(0xFFEEF2F5);
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFFADB5BD);
    final cancelBorderColor = isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300;
    final cancelTextColor = isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: isDark ? Border.all(color: Colors.white.withValues(alpha: 0.08)) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.18),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: activeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.business_outlined, color: activeColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text('Add Department',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800, color: titleColor)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Enter the name of the new department below.',
                style: TextStyle(fontSize: 13, color: subtitleColor, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            TextField(
              controller: _modalCtrl,
              autofocus: true,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: inputTextColor),
              decoration: InputDecoration(
                hintText: 'Department name...',
                hintStyle: TextStyle(color: hintColor, fontSize: 13, fontWeight: FontWeight.w500),
                filled: true,
                fillColor: inputFill,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: activeColor.withValues(alpha: 0.5))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cancelTextColor,
                      side: BorderSide(color: cancelBorderColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _adding ? null : _submit,
                    icon: _adding
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add, size: 18),
                    label: Text(_adding ? 'Adding...' : 'Add Department',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: activeColor.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}