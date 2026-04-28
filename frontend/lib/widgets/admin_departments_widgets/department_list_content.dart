import 'dart:async';
import 'package:flutter/material.dart';
import 'add_department_dialog.dart';

const _kBlue = Color(0xFF00022E);
const _kBarColor = Color(0xFFEEF2F5);
const _inputStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87);
const _hintStyle = TextStyle(color: Color(0xFFADB5BD), fontSize: 13, fontWeight: FontWeight.w500);

int _id(dynamic v) => v == null ? 0 : (v as num).toInt();

class DepartmentListContent extends StatefulWidget {
  final bool loading;
  final List<dynamic> items;
  final String searchHint;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(int id, String name) onEdit;
  final Future<void> Function(int id, String name) onDelete;

  const DepartmentListContent({
    super.key,
    required this.loading,
    required this.items,
    required this.searchHint,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DepartmentListContent> createState() => _DepartmentListContentState();
}

class _DepartmentListContentState extends State<DepartmentListContent> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _showAddModal() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AddDepartmentDialog(onAdd: widget.onAdd),
    );
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items.where((item) => (item['name'] as String? ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search bar + Add button ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: _kBarColor,
            border: Border(bottom: BorderSide(color: _kBlue.withValues(alpha: 0.15), width: 0.5)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: _inputStyle,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: _hintStyle,
                  prefixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                    onPressed: () {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      setState(() => _searchQuery = _searchCtrl.text.trim());
                    },
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (v) {
                  setState(() {});
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => _searchQuery = v.trim());
                  });
                },
                onSubmitted: (v) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  setState(() => _searchQuery = v.trim());
                },
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _showAddModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),

        // ── List ──
        if (widget.loading)
          const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(children: [
              Icon(_searchQuery.isEmpty ? Icons.inbox_outlined : Icons.search_off, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isEmpty ? 'No departments yet.' : 'No departments match "$_searchQuery".',
                style: const TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 4),
                const Text('Press the Add button to create one.', style: TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ]),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 20),
              itemBuilder: (context, i) {
                final item = filtered[i];
                final id = _id(item['id']);
                final name = item['name'] as String? ?? '';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _kBlue.withValues(alpha: 0.08),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: _kBlue, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.black87)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Edit',
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: _kBlue),
                          onPressed: () => widget.onEdit(id, name),
                        ),
                      ),
                      Tooltip(
                        message: 'Delete',
                        child: IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                          onPressed: () => widget.onDelete(id, name),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}