import 'package:flutter/material.dart';

const _kBlue = Color(0xFF00022E);
const _inputStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87);
const _hintStyle = TextStyle(color: Color(0xFFADB5BD), fontSize: 13, fontWeight: FontWeight.w500);

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 32, offset: const Offset(0, 8)),
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
                  decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.business_outlined, color: _kBlue, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('Add Department', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey.shade400, size: 20),
                  splashRadius: 18,
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Enter the name of the new department below.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            TextField(
              controller: _modalCtrl,
              autofocus: true,
              style: _inputStyle,
              decoration: InputDecoration(
                hintText: 'Department name...',
                hintStyle: _hintStyle,
                filled: true,
                fillColor: const Color(0xFFEEF2F5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _kBlue.withValues(alpha: 0.5))),
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
                      foregroundColor: Colors.black54,
                      side: BorderSide(color: Colors.grey.shade300),
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
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.add, size: 18),
                    label: Text(_adding ? 'Adding...' : 'Add Department', style: const TextStyle(fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _kBlue.withValues(alpha: 0.6),
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