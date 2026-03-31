import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/sidebar.dart';

const _kCrimson = Color(0xFF7B0D1E);

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _departments = [];
  List<dynamic> _positions   = [];
  bool _loading = true;
  final _deptCtrl   = TextEditingController();
  final _posCtrl    = TextEditingController();
  final _deptSearch = TextEditingController();
  final _posSearch  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _deptSearch.addListener(() => setState(() {}));
    _posSearch.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _deptCtrl.dispose();
    _posCtrl.dispose();
    _deptSearch.dispose();
    _posSearch.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final d = await ApiService.getConfig(type: 'department');
    final p = await ApiService.getConfig(type: 'position');
    if (mounted) {
      setState(() {
        _departments = d['items'] ?? [];
        _positions   = p['items'] ?? [];
        _loading     = false;
      });
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────
  Future<void> _add(String name, String type) async {
    if (name.trim().isEmpty) return;
    final res = await ApiService.createConfig(name.trim(), type);
    if (res['ok'] == true) {
      await _loadAll();
      if (type == 'department') {
        _deptCtrl.clear();
      } else {
        _posCtrl.clear();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Failed to add'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  // ── Edit — inline dialog ──────────────────────────────────────────────────
  Future<void> _edit(int id, String currentName, String type) async {
    final ctrl = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kCrimson.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_outlined,
                color: _kCrimson, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Edit ${type[0].toUpperCase()}${type.substring(1)}',
            style: const TextStyle(fontSize: 17),
          ),
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
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kCrimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    ctrl.dispose();

    if (newName == null || newName.isEmpty || newName == currentName) return;
    if (!mounted) return;

    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white)),
          SizedBox(width: 12),
          Text('Saving...'),
        ]),
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.grey.shade800,
      ),
    );

    final res = await ApiService.updateConfig(id, newName);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    if (res['ok'] == true) {
      await _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('"$newName" updated successfully.'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['error'] ?? 'Failed to update'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _delete(int id, String name, String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.delete_forever,
                color: Colors.red.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Confirm Delete', style: TextStyle(fontSize: 17)),
        ]),
        content: RichText(
          text: TextSpan(
            style:
                const TextStyle(color: Colors.black87, fontSize: 14),
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
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever, size: 16),
            label: const Text('Delete'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final res = await ApiService.deleteConfig(id);
    if (res['ok'] == true) {
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" removed.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ── Tab content ───────────────────────────────────────────────────────────
  Widget _buildTab(
    List<dynamic> allItems,
    TextEditingController addCtrl,
    TextEditingController searchCtrl,
    String type,
  ) {
    // Filter by search query
    final query = searchCtrl.text.trim().toLowerCase();
    final items = query.isEmpty
        ? allItems
        : allItems
            .where((e) =>
                (e['name'] as String? ?? '')
                    .toLowerCase()
                    .contains(query))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Add + Search row ───────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            border:
                Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Column(
            children: [
              // Add new
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: addCtrl,
                    decoration: InputDecoration(
                      hintText:
                          'New ${type[0].toUpperCase()}${type.substring(1)} name...',
                      filled: true,
                      fillColor: const Color(0xFFEEF2F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (v) => _add(v, type),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _add(
                      type == 'department'
                          ? _deptCtrl.text
                          : _posCtrl.text,
                      type),
                  icon: const Icon(Icons.add, size: 18),
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
              const SizedBox(height: 12),
              // Search
              TextField(
                controller: searchCtrl,
                decoration: InputDecoration(
                  hintText:
                      'Search ${type}s...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFEEF2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),

        // ── List ───────────────────────────────────────────────────────
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (allItems.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(children: [
              Icon(Icons.inbox_outlined,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No ${type}s added yet.',
                  style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text('Use the field above to add one.',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 12)),
            ]),
          )
        else if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(children: [
              Icon(Icons.search_off,
                  size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text('No ${type}s match "$query".',
                  style: TextStyle(color: Colors.grey.shade500)),
            ]),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 20),
            itemBuilder: (context, i) {
              final item = items[i];
              final id   = (item['id'] as num).toInt();
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
                        icon: Icon(Icons.edit_outlined,
                            color: Colors.blue.shade400, size: 20),
                        onPressed: () => _edit(id, name, type),
                      ),
                    ),
                    // Delete button
                    Tooltip(
                      message: 'Delete',
                      child: IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 20),
                        onPressed: () => _delete(id, name, type),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/config'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Departments & Positions',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage the dropdown options available in registration and profiles.',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                  const SizedBox(height: 24),

                  // Tab card
                  Expanded(
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.business_outlined,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.work_outline,
                                        size: 16),
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
                                  child: _buildTab(_departments,
                                      _deptCtrl, _deptSearch, 'department'),
                                ),
                                SingleChildScrollView(
                                  child: _buildTab(_positions,
                                      _posCtrl, _posSearch, 'position'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// ── Count badge ───────────────────────────────────────────────────────────────
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
        child: Text(
          '$count',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
      );
}