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
  final _deptCtrl = TextEditingController();
  final _posCtrl  = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _deptCtrl.dispose();
    _posCtrl.dispose();
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

  Future<void> _delete(int id, String name, String type) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Confirm Delete'),
        content: Text('Remove "$name" from ${type}s?'),
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
    if (confirmed == true) {
      final res = await ApiService.deleteConfig(id);
      if (res['ok'] == true) {
        await _loadAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"$name" removed.'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }

  Widget _buildTab(
      List<dynamic> items, TextEditingController ctrl, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Add new row
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
                controller: ctrl,
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
                  type == 'department' ? _deptCtrl.text : _posCtrl.text,
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
        ),

        // List
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (items.isEmpty)
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
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 20),
                  tooltip: 'Remove',
                  onPressed: () => _delete(id, name, type),
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
                                  child: _buildTab(
                                      _departments, _deptCtrl, 'department'),
                                ),
                                SingleChildScrollView(
                                  child: _buildTab(
                                      _positions, _posCtrl, 'position'),
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

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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