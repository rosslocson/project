import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';
import '../services/api_service.dart';

const _kCrimson = Color(0xFF7B0D1E);

int _id(dynamic v) => v == null ? 0 : (v as num).toInt();

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  // _isSidebarVisible removed - using AppScaffold sidebar
  List<dynamic> _departments = [];
  List<dynamic> _positions   = [];
  bool _loadingDept = true;
  bool _loadingPos  = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadDepartments();
    _loadPositions();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() => _loadingDept = true);
    final res = await ApiService.getDepartments();
    if (mounted) {
      setState(() {
        _departments = res['items'] ?? [];
        _loadingDept  = false;
      });
    }
  }

  Future<void> _loadPositions() async {
    setState(() => _loadingPos = true);
    final res = await ApiService.getPositions();
    if (mounted) {
      setState(() {
        _positions  = res['items'] ?? [];
        _loadingPos = false;
      });
    }
  }

  // ── Add ────────────────────────────────────────────────────────────────────
  Future<void> _addDepartment(String name) async {
    final res = await ApiService.createDepartment(name.trim());
    if (res['ok'] == true) {
      await _loadDepartments();
    } else if (mounted) {
      _showError(res['error'] ?? 'Failed to add department');
    }
  }

  Future<void> _addPosition(String name) async {
    final res = await ApiService.createPosition(name.trim());
    if (res['ok'] == true) {
      await _loadPositions();
    } else if (mounted) {
      _showError(res['error'] ?? 'Failed to add position');
    }
  }

  // ── Edit ───────────────────────────────────────────────────────────────────
  Future<void> _editItem({
    required int id,
    required String currentName,
    required String type, // 'department' or 'position'
  }) async {
    final ctrl = TextEditingController(text: currentName);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          const Icon(Icons.edit_outlined, color: _kCrimson, size: 20),
          const SizedBox(width: 8),
          Text('Edit ${type[0].toUpperCase()}${type.substring(1)}'),
        ]),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Name',
            filled: true,
            fillColor: const Color(0xFFEEF2F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kCrimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();

    if (saved == null || saved == currentName) return;

    final res = type == 'department'
        ? await ApiService.updateDepartment(id, saved)
        : await ApiService.updatePosition(id, saved);

    if (res['ok'] == true) {
      type == 'department'
          ? await _loadDepartments()
          : await _loadPositions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$saved" updated.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else if (mounted) {
      _showError(res['error'] ?? 'Update failed');
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteItem({
    required int id,
    required String name,
    required String type,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Icon(Icons.delete_forever, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          const Text('Confirm Delete'),
        ]),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 14),
            children: [
              const TextSpan(text: 'Remove '),
              TextSpan(
                  text: '"$name"',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              TextSpan(text: ' from ${type}s?'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = type == 'department'
        ? await ApiService.deleteDepartment(id)
        : await ApiService.deletePosition(id);

    if (res['ok'] == true) {
      type == 'department'
          ? await _loadDepartments()
          : await _loadPositions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" deleted.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else if (mounted) {
      _showError(res['error'] ?? 'Delete failed');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Tab builders ───────────────────────────────────────────────────────────
  Widget _buildDeptTab() {
    return _ItemTab(
      loading: _loadingDept,
      items: _departments,
      type: 'department',
      hintText: 'New department name...',
      onAdd: _addDepartment,
      onEdit: (id, name) => _editItem(id: id, currentName: name, type: 'department'),
      onDelete: (id, name) => _deleteItem(id: id, name: name, type: 'department'),
    );
  }

  Widget _buildPosTab() {
    return _ItemTab(
      loading: _loadingPos,
      items: _positions,
      type: 'position',
      hintText: 'New position name...',
      onAdd: _addPosition,
      onEdit: (id, name) => _editItem(id: id, currentName: name, type: 'position'),
      onDelete: (id, name) => _deleteItem(id: id, name: name, type: 'position'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Departments & Positions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Manage dropdown options shown during registration and account settings.',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13),
            ),
          ),

          Expanded(
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabs,
                    labelColor: _kCrimson,
                    indicatorColor: _kCrimson,
                    unselectedLabelColor: Colors.grey,
                    indicatorWeight: 3,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.business_outlined,
                                size: 16),
                            const SizedBox(width: 6),
                            const Text('Departments'),
                            if (_departments.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _CountBadge(_departments.length),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.work_outline, size: 16),
                            const SizedBox(width: 6),
                            const Text('Positions'),
                            if (_positions.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _CountBadge(_positions.length),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        SingleChildScrollView(
                            child: _buildDeptTab()),
                        SingleChildScrollView(
                            child: _buildPosTab()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable tab content ──────────────────────────────────────────────────────
class _ItemTab extends StatefulWidget {
  final bool loading;
  final List<dynamic> items;
  final String type;
  final String hintText;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(int id, String name) onEdit;
  final Future<void> Function(int id, String name) onDelete;

  const _ItemTab({
    required this.loading,
    required this.items,
    required this.type,
    required this.hintText,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ItemTab> createState() => _ItemTabState();
}

class _ItemTabState extends State<_ItemTab> {
  final _ctrl    = TextEditingController();
  bool  _adding  = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _adding = true);
    await widget.onAdd(name);
    if (mounted) {
      _ctrl.clear();
      setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Add row ─────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
                bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: const Color(0xFFEEF2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _adding ? null : _submit,
              icon: _adding
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCrimson,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),

        // ── List ────────────────────────────────────────────────────────
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (widget.items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(
                'No ${widget.type}s yet.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                'Add one using the field above.',
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 12),
              ),
            ]),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 20),
            itemBuilder: (context, i) {
              final item = widget.items[i];
              final id   = _id(item['id']);
              final name = item['name'] as String? ?? '';

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: _kCrimson.withValues(alpha: 0.08),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: _kCrimson,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button
                    Tooltip(
                      message: 'Edit',
                      child: IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            size: 18, color: _kCrimson),
                        onPressed: () => widget.onEdit(id, name),
                      ),
                    ),
                    // Delete button
                    Tooltip(
                      message: 'Delete',
                      child: IconButton(
                        icon: Icon(Icons.delete_outline,
                            size: 18, color: Colors.red.shade400),
                        onPressed: () => widget.onDelete(id, name),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: _kCrimson,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$count',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      );
}