import 'dart:async';
import 'package:flutter/material.dart';
import 'add_department_dialog.dart';
import '../app_theme.dart';

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
    return widget.items
        .where((item) =>
            (item['name'] as String? ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    final theme   = context.internTheme;
    final isDark  = context.isDarkInternTheme;
    final activeColor =
        isDark ? const Color(0xFF7367F0) : const Color(0xFF00022E);

    final barColor      = isDark ? theme.surface : theme.sidebarBackground;
    final inputFillColor = isDark ? theme.surface : theme.sidebarBackground;
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final hintColor =
        isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFFADB5BD);
    final dividerColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;
    final emptyIconColor =
        isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300;
    final emptyTextColor =
        isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;
    final emptySubTextColor =
        isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black38;
    final listTileTextColor =
        isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search bar + Add button ───────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: barColor,
            border: Border(
              bottom: BorderSide(
                color: activeColor.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
          ),
          // FIX: IntrinsicHeight + Row with Expanded search field ensures
          // the search bar never overflows on narrow screens. The Add button
          // uses a fixed minimum width via constraints rather than padding.
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Search field takes all remaining space
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: inputTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    hintStyle: TextStyle(
                      color: hintColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: IconButton(
                      icon: Icon(Icons.search, color: hintColor, size: 18),
                      onPressed: () {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        setState(
                            () => _searchQuery = _searchCtrl.text.trim());
                      },
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon:
                                Icon(Icons.clear, color: hintColor, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: inputFillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: theme.border.withValues(alpha: 0.15),
                          width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: theme.border.withValues(alpha: 0.15),
                          width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onChanged: (v) {
                    setState(() {});
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce =
                        Timer(const Duration(milliseconds: 300), () {
                      setState(() => _searchQuery = v.trim());
                    });
                  },
                  onSubmitted: (v) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    setState(() => _searchQuery = v.trim());
                  },
                ),
              ),

              const SizedBox(width: 10),

              // FIX: Add button — use a compact icon-only button on very
              // narrow screens, full label otherwise. LayoutBuilder provides
              // the true available width so we never overflow.
              LayoutBuilder(
                builder: (context, constraints) {
                  // constraints.maxWidth here is the button's own slot after
                  // the Expanded search field has taken its share. However
                  // LayoutBuilder inside a Row sibling doesn't constrain
                  // itself usefully — use MediaQuery width instead.
                  final screenW = MediaQuery.of(context).size.width;
                  final compact = screenW < 480;

                  return ElevatedButton(
                    onPressed: _showAddModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      // Fixed vertical padding; horizontal shrinks on mobile
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 20,
                        vertical: 12,
                      ),
                      minimumSize: Size(compact ? 40 : 90, 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: compact
                        // Icon-only on very small screens
                        ? const Icon(Icons.add, size: 20)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 18),
                              SizedBox(width: 6),
                              Text('Add',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                  );
                },
              ),
            ],
          ),
        ),

        // ── List ─────────────────────────────────────────────────────
        if (widget.loading)
          Padding(
            padding: const EdgeInsets.all(40),
            child: Center(
                child: CircularProgressIndicator(color: activeColor)),
          )
        else if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _searchQuery.isEmpty
                      ? Icons.inbox_outlined
                      : Icons.search_off,
                  size: 48,
                  color: emptyIconColor,
                ),
                const SizedBox(height: 12),
                Text(
                  _searchQuery.isEmpty
                      ? 'No departments yet.'
                      : 'No departments match "$_searchQuery".',
                  style: TextStyle(
                    color: emptyTextColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_searchQuery.isEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Press the Add button to create one.',
                    style: TextStyle(
                      color: emptySubTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          )
        else
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, indent: 20, color: dividerColor),
              itemBuilder: (context, i) {
                final item = filtered[i];
                final id   = _id(item['id']);
                final name = item['name'] as String? ?? '';

                return ListTile(
                  // FIX: reduce horizontal padding so leading + title +
                  // trailing all fit without overflow on narrow screens.
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 2),

                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: activeColor.withValues(alpha: 0.08),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  title: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: listTileTextColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),

                  // ─────────────────────────────────────────────────────
                  // FIX: "Trailing widget consumes the entire tile width"
                  //
                  // The error occurs because ListTile measures the trailing
                  // widget first and gives it whatever width it requests.
                  // A bare Row(mainAxisSize: min) with two IconButtons
                  // requests ~96 px (each IconButton defaults to 48 px tap
                  // target), which on narrow tiles leaves nothing for the
                  // title — Flutter then throws the warning.
                  //
                  // Solution: wrap in a SizedBox with a fixed width that
                  // exactly fits both icons, and strip the default 48 px
                  // minimum from IconButton via constraints + padding zero.
                  // ─────────────────────────────────────────────────────
                  trailing: SizedBox(
                    width: 72, // 32px × 2 icons + 8px gap — no overflow
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Edit',
                          child: IconButton(
                            icon: Icon(Icons.edit_outlined,
                                size: 18, color: activeColor),
                            onPressed: () => widget.onEdit(id, name),
                            // Remove default 48px minimum tap target so the
                            // button stays inside the SizedBox.
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Delete',
                          child: IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18, color: Colors.red.shade400),
                            onPressed: () => widget.onDelete(id, name),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}