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
 List<dynamic> _positions = [];
 bool _loadingDept = true;
 bool _loadingPos = true;
 late AnimationController _bgAnimController;


 @override
 void initState() {
   super.initState();
   _tabs = TabController(length: 2, vsync: this);
   _bgAnimController = AnimationController(
     vsync: this,
     duration: const Duration(seconds: 150),
   )..repeat();
   _loadDepartments();
   _loadPositions();
 }


 @override
 void dispose() {
   _tabs.dispose();
   _bgAnimController.dispose();
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


 Future<void> _loadPositions() async {
   setState(() => _loadingPos = true);
   final res = await ApiService.getPositions();
   if (mounted) {
     setState(() {
       _positions = res['items'] ?? [];
       _loadingPos = false;
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


 Future<void> _addPosition(String name) async {
   final res = await ApiService.createPosition(name.trim());
   if (res['ok'] == true) {
     await _loadPositions();
   } else if (mounted) {
     _showError(res['error'] ?? 'Failed to add position');
   }
 }


 Future<void> _editItem({
   required int id,
   required String currentName,
   required String type,
 }) async {
   final ctrl = TextEditingController(text: currentName);
   final saved = await showDialog<String>(
     context: context,
     builder: (ctx) => AlertDialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
       title: Row(children: [
         const Icon(Icons.edit_outlined, color: _kBlue, size: 20),
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


   final res = type == 'department'
       ? await ApiService.updateDepartment(id, saved)
       : await ApiService.updatePosition(id, saved);


   if (res['ok'] == true) {
     type == 'department' ? await _loadDepartments() : await _loadPositions();
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
   required String type,
 }) async {
   final confirmed = await showDialog<bool>(
     context: context,
     builder: (ctx) => AlertDialog(
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
       title: Row(children: [
Icon(Icons.delete_forever, color: Colors.blue.shade700, size: 20),
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
               backgroundColor: Colors.blue.shade700,
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
     type == 'department' ? await _loadDepartments() : await _loadPositions();
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
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Expanded(
                       child: SingleChildScrollView(
                         padding: const EdgeInsets.all(32),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             // ── Header ────────────────────────────
                             Row(
                               children: [
                                 if (!_isSidebarOpen) ...[
                                   Container(
                                     margin: const EdgeInsets.only(right: 16),
                                     decoration: BoxDecoration(
                                       color: Colors.white.withOpacity(0.05),
                                       borderRadius: BorderRadius.circular(12),
                                       border: Border.all(
                                         color: Colors.white.withOpacity(0.15),
                                         width: 1,
                                       ),
                                     ),
                                     child: IconButton(
                                       padding: const EdgeInsets.all(12),
                                       onPressed: () => setState(
                                           () => _isSidebarOpen = true),
                                       icon: const _HamburgerIcon(),
                                       tooltip: 'Open Sidebar',
                                       splashColor:
                                           Colors.white.withOpacity(0.1),
                                       highlightColor: Colors.transparent,
                                     ),
                                   ),
                                 ],
                                 // ── FIXED: matches My Profile title style ──
                                 Text(
                                   'Departments & Positions',
                                   style: Theme.of(context)
                                       .textTheme
                                       .headlineMedium
                                       ?.copyWith(
                                         fontWeight: FontWeight.w800,
                                         color: Colors.white,
                                         letterSpacing: 0.5,
                                       ),
                                 ),
                               ],
                             ),
                             const SizedBox(height: 24),


                             // ── Tab card ─────────────────────────
                             Container(
                               decoration: BoxDecoration(
                                 color: Colors.white.withOpacity(0.95),
                                 borderRadius: BorderRadius.circular(16),
                               ),
                               child: ClipRRect(
                                 borderRadius: BorderRadius.circular(16),
                                 child: Column(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     TabBar(
                                       controller: _tabs,
                                     labelColor: _kBlue,
                                       indicatorColor: _kBlue,
                                       unselectedLabelColor: Colors.black87,
                                       indicatorWeight: 3,
                                       // FIXED: matches My Profile section header weight
                                       labelStyle: const TextStyle(
                                         fontSize: 16,
                                         fontWeight: FontWeight.w800,
                                       ),
                                       unselectedLabelStyle: const TextStyle(
                                         fontSize: 16,
                                         fontWeight: FontWeight.w600,
                                       ),
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
                                               if (_departments
                                                   .isNotEmpty) ...[
                                                 const SizedBox(width: 6),
                                                 _CountBadge(
                                                     _departments.length),
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
                                                 _CountBadge(
                                                     _positions.length),
                                               ],
                                             ],
                                           ),
                                         ),
                                       ],
                                     ),
                                     SizedBox(
                                       height: 520,
                                       child: TabBarView(
                                         controller: _tabs,
                                         children: [
                                           _ItemTab(
                                             loading: _loadingDept,
                                             items: _departments,
                                             type: 'department',
                                             addHint: 'New department name...',
                                             searchHint:
                                                 'Search departments...',
                                             onAdd: _addDepartment,
                                             onEdit: (id, name) => _editItem(
                                                 id: id,
                                                 currentName: name,
                                                 type: 'department'),
                                             onDelete: (id, name) =>
                                                 _deleteItem(
                                                     id: id,
                                                     name: name,
                                                     type: 'department'),
                                           ),
                                           _ItemTab(
                                             loading: _loadingPos,
                                             items: _positions,
                                             type: 'position',
                                             addHint: 'New position name...',
                                             searchHint: 'Search positions...',
                                             onAdd: _addPosition,
                                             onEdit: (id, name) => _editItem(
                                                 id: id,
                                                 currentName: name,
                                                 type: 'position'),
                                             onDelete: (id, name) =>
                                                 _deleteItem(
                                                     id: id,
                                                     name: name,
                                                     type: 'position'),
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
 final String type;
 final String addHint;
 final String searchHint;
 final Future<void> Function(String name) onAdd;
 final Future<void> Function(int id, String name) onEdit;
 final Future<void> Function(int id, String name) onDelete;


 const _ItemTab({
   required this.loading,
   required this.items,
   required this.type,
   required this.addHint,
   required this.searchHint,
   required this.onAdd,
   required this.onEdit,
   required this.onDelete,
 });


 @override
 State<_ItemTab> createState() => _ItemTabState();
}


class _ItemTabState extends State<_ItemTab> {
 final _addCtrl = TextEditingController();
 final _searchCtrl = TextEditingController();
 bool _adding = false;
 String _searchQuery = '';


 static const _kBarColor = Color(0xFFEEF2F5);


 @override
 void dispose() {
   _addCtrl.dispose();
   _searchCtrl.dispose();
   super.dispose();
 }


 Future<void> _submit() async {
   final name = _addCtrl.text.trim();
   if (name.isEmpty) return;
   setState(() => _adding = true);
   await widget.onAdd(name);
   if (mounted) {
     _addCtrl.clear();
     setState(() => _adding = false);
   }
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


   // FIXED: consistent hint/input style matching My Profile content
   const inputStyle = TextStyle(
     fontSize: 12,
     fontWeight: FontWeight.w600,
     color: Colors.black87,
   );
   const hintStyle = TextStyle(
     color: Color(0xFFADB5BD),
     fontSize: 13,
     fontWeight: FontWeight.w500,
   );


   return Column(
     crossAxisAlignment: CrossAxisAlignment.stretch,
     children: [
       // ── 1. Add bar ──────────────────────────────────────────────
       Container(
         padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
         decoration: BoxDecoration(
           color: _kBarColor,
           border:
               Border(bottom: BorderSide(color: _kBlue.withOpacity(0.15))),
         ),
         child: Row(children: [
           Expanded(
             child: TextField(
               controller: _addCtrl,
               style: inputStyle,
               decoration: InputDecoration(
                 hintText: widget.addHint,
                 hintStyle: hintStyle,
                 filled: true,
                 fillColor: Colors.white,
                 border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(10),
                   borderSide: BorderSide.none,
                 ),
                 contentPadding:
                     const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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


       // ── 2. Search bar ───────────────────────────────────────────
       Container(
         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
         color: _kBarColor,
         child: TextField(
           controller: _searchCtrl,
           style: inputStyle,
           decoration: InputDecoration(
             hintText: widget.searchHint,
             hintStyle: hintStyle,
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


       // ── Divider ─────────────────────────────────────────────────
       Container(
         height: 1,
         color: _kBlue.withOpacity(0.15),
       ),


       // ── 3. List ─────────────────────────────────────────────────
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
                   ? 'No ${widget.type}s yet.'
                   : 'No ${widget.type}s match "$_searchQuery".',
               // FIXED: matches My Profile field value style
               style: const TextStyle(
                 color: Colors.black54,
                 fontSize: 15,
                 fontWeight: FontWeight.w600,
               ),
             ),
             if (_searchQuery.isEmpty) ...[
               const SizedBox(height: 4),
               const Text(
                 'Add one using the field above.',
                 // FIXED: matches My Profile field label style
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


// ── Count Badge ───────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
 final int count;
 const _CountBadge(this.count);


 @override
 Widget build(BuildContext context) => Container(
       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
       decoration: BoxDecoration(
         color: _kBlue,
         borderRadius: BorderRadius.circular(10),
       ),
       child: Text('$count',
           style: const TextStyle(
               color: Colors.white,
               fontSize: 10,
               fontWeight: FontWeight.bold)),
     );
}
