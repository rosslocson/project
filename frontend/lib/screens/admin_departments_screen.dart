import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/admin_sidebar.dart';

const _kBlue = Color(0xFF00022E);

// ── Custom Hamburger Icon ────────────────────────────────────────────────────
class _HamburgerIcon extends StatelessWidget {
  const _HamburgerIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

int _id(dynamic v) => v == null ? 0 : (v as num).toInt();

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});
  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen>
    with TickerProviderStateMixin {
  late TabController _tabs;
  bool _isSidebarOpen = true;
  List<dynamic> _departments = [];
  bool _loadingDept = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 1, vsync: this);
    _loadDepartments();
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
        _loadingDept = false;
      });
    }
  }

  Future<void> _addDepartment(String name) async {
    final res = await ApiService.createDepartment(name.trim());
    if (res['ok'] == true) {
      await _loadDepartments();
    } else if (mounted) {
      _showError(res['error'] ?? 'Failed to add department');
    }
  }

  Future<void> _editItem({
    required int id,
    required String currentName,
  }) async {
    final ctrl = TextEditingController(text: currentName);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(children: [
          Icon(Icons.edit_outlined, color: _kBlue, size: 20),
          SizedBox(width: 8),
          Text('Edit Department'),
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
              backgroundColor: _kBlue,
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

    final res = await ApiService.updateDepartment(id, saved);

    if (res['ok'] == true) {
      await _loadDepartments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$saved" updated.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } else if (mounted) {
      _showError(res['error'] ?? 'Update failed');
    }
  }

  Future<void> _deleteItem({
    required int id,
    required String name,
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
                text: name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' from departments?'),
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

    final res = await ApiService.deleteDepartment(id);

    if (res['ok'] == true) {
      await _loadDepartments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"$name" deleted.'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          // ── Sidebar ──────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: _isSidebarOpen ? 250 : 0,
            child: _isSidebarOpen
                ? AdminSidebar(
                    currentRoute: '/config',
                    onClose: () => setState(() => _isSidebarOpen = false),
                  )
                : null,
          ),

          // ── Main content ────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/space_background.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top bar ──────────────────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 40, right: 40, top: 28),
                        child: Row(
                          children: [
                            if (!_isSidebarOpen) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.15)),
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(12),
                                  onPressed: () =>
                                      setState(() => _isSidebarOpen = true),
                                  icon: const _HamburgerIcon(),
                                  tooltip: 'Open Sidebar',
                                  splashColor: Colors.white.withOpacity(0.1),
                                  highlightColor: Colors.transparent,
                                ),
                              ),
                            ],
                            Text(
                              'Departments',
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall
                                  ?.copyWith(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // ── Content ───────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              left: 100, right: 100, bottom: 28),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Column(
                                children: [
                                  // ── Tab bar ───────────────────────
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                            color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: TabBar(
                                      controller: _tabs,
                                      labelColor: _kBlue,
                                      indicatorColor: _kBlue,
                                      indicatorWeight: 3.5,
                                      unselectedLabelColor:
                                          Colors.grey.shade500,
                                      labelStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      unselectedLabelStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      dividerColor: Colors.transparent,
                                      tabs: const [
                                        Tab(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                  Icons.business_outlined,
                                                  size: 16),
                                              SizedBox(width: 6),
                                              Text('Departments'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ── Tab content ───────────────────
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabs,
                                      children: [
                                        _ItemTab(
                                          loading: _loadingDept,
                                          items: _departments,
                                          searchHint: 'Search departments...',
                                          onAdd: _addDepartment,
                                          onEdit: (id, name) => _editItem(
                                              id: id, currentName: name),
                                          onDelete: (id, name) =>
                                              _deleteItem(id: id, name: name),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
  final String searchHint;
  final Future<void> Function(String name) onAdd;
  final Future<void> Function(int id, String name) onEdit;
  final Future<void> Function(int id, String name) onDelete;

  const _ItemTab({
    required this.loading,
    required this.items,
    required this.searchHint,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ItemTab> createState() => _ItemTabState();
}

class _ItemTabState extends State<_ItemTab> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _kBarColor = Color(0xFFEEF2F5);

  static const _inputStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );
  static const _hintStyle = TextStyle(
    color: Color(0xFFADB5BD),
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAddModal() async {
    final modalCtrl = TextEditingController();
    bool adding = false;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                width: 420,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
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
                            color: _kBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.business_outlined,
                              color: _kBlue, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add Department',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close,
                              color: Colors.grey.shade400, size: 20),
                          splashRadius: 18,
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the name of the new department below.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: modalCtrl,
                      autofocus: true,
                      style: _inputStyle,
                      decoration: InputDecoration(
                        hintText: 'Department name...',
                        hintStyle: _hintStyle,
                        filled: true,
                        fillColor: const Color(0xFFEEF2F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: _kBlue.withOpacity(0.5)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: (_) async {
                        final name = modalCtrl.text.trim();
                        if (name.isEmpty || adding) return;
                        setModalState(() => adding = true);
                        await widget.onAdd(name);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black54,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: adding
                                ? null
                                : () async {
                                    final name = modalCtrl.text.trim();
                                    if (name.isEmpty) return;
                                    setModalState(() => adding = true);
                                    await widget.onAdd(name);
                                    if (ctx.mounted) Navigator.pop(ctx);
                                  },
                            icon: adding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.add, size: 18),
                            label: Text(
                              adding ? 'Adding...' : 'Add Department',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _kBlue.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    modalCtrl.dispose();
  }

  List<dynamic> get _filtered {
    if (_searchQuery.isEmpty) return widget.items;
    final q = _searchQuery.toLowerCase();
    return widget.items
        .where(
            (item) => (item['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: BoxDecoration(
            color: _kBarColor,
            border: Border(
                bottom:
                    BorderSide(color: _kBlue.withOpacity(0.15), width: 0.5)),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                style: _inputStyle,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: _hintStyle,
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey.shade400, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onChanged: (v) => setState(() => _searchQuery = v.trim()),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
        Container(height: 0.5, color: _kBlue.withOpacity(0.15)),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(children: [
              Icon(
                _searchQuery.isEmpty ? Icons.inbox_outlined : Icons.search_off,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                _searchQuery.isEmpty
                    ? 'No departments yet.'
                    : 'No departments match "$_searchQuery".',
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_searchQuery.isEmpty) ...[
                const SizedBox(height: 4),
                const Text(
                  'Press the Add button to create one.',
                  style: TextStyle(
                    color: Colors.black38,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: _kBlue.withOpacity(0.08),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: _kBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tooltip(
                        message: 'Edit',
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: _kBlue),
                          onPressed: () => widget.onEdit(id, name),
                        ),
                      ),
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
          ),
      ],
    );
  }
}
