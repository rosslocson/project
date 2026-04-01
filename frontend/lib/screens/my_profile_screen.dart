import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/sidebar.dart';

const _kCrimson = Color(0xFF7B0D1E);

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user    = context.watch<AuthProvider>().user;
    final isAdmin = user?['role'] == 'admin';

    final first = user?['first_name'] as String? ?? '';
    final last  = user?['last_name']  as String? ?? '';
    String initials = '';
    if (first.isNotEmpty) initials += first[0];
    if (last.isNotEmpty)  initials += last[0];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      body: Row(
        children: [
          const Sidebar(currentRoute: '/profile'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Header row ───────────────────────────────────────
                    Row(
                      children: [
                        Text(
                          'My Profile',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        // ── Edit Profile button → goes to /profile/edit ──
                        OutlinedButton.icon(
                          onPressed: () {
                            context.go('/profile/edit');
                          },
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kCrimson,
                            side: const BorderSide(color: _kCrimson),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Avatar + name card ───────────────────────────────
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor:
                                  _kCrimson.withValues(alpha: 0.1),
                              backgroundImage:
                                  (user?['avatar_url'] as String? ?? '')
                                          .isNotEmpty
                                      ? NetworkImage(user!['avatar_url'])
                                      : null,
                              child: (user?['avatar_url'] as String? ?? '')
                                      .isEmpty
                                  ? Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: _kCrimson,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$first $last',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?['email'] ?? '',
                                    style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      _Badge(
                                        label: (user?['role'] ?? 'user')
                                            .toUpperCase(),
                                        color: isAdmin
                                            ? Colors.red.shade700
                                            : _kCrimson,
                                        bg: isAdmin
                                            ? Colors.red.shade50
                                            : _kCrimson
                                                .withValues(alpha: 0.08),
                                      ),
                                      _Badge(
                                        label: (user?['is_active'] == true)
                                            ? 'ACTIVE'
                                            : 'INACTIVE',
                                        color: (user?['is_active'] == true)
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700,
                                        bg: (user?['is_active'] == true)
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Info grid ────────────────────────────────────────
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            _infoRow(context, [
                              _Field('First Name', first.isEmpty ? '—' : first),
                              _Field('Last Name', last.isEmpty ? '—' : last),
                            ]),
                            const SizedBox(height: 16),
                            _infoRow(context, [
                              _Field('Email', user?['email'] ?? '—'),
                              _Field(
                                'Phone',
                                (user?['phone'] as String? ?? '').isEmpty
                                    ? '—'
                                    : user!['phone'],
                              ),
                            ]),
                            const SizedBox(height: 16),
                            _infoRow(context, [
                              _Field(
                                'Department',
                                (user?['department'] as String? ?? '').isEmpty
                                    ? '—'
                                    : user!['department'],
                              ),
                              _Field(
                                'Position',
                                (user?['position'] as String? ?? '').isEmpty
                                    ? '—'
                                    : user!['position'],
                              ),
                            ]),
                            if ((user?['bio'] as String? ?? '').isNotEmpty) ...[
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 16),
                              const Text('Bio',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black54)),
                              const SizedBox(height: 6),
                              Text(
                                user!['bio'],
                                style: const TextStyle(
                                    fontSize: 14, height: 1.5),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(BuildContext context, List<_Field> fields) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth > 400) {
        final rowChildren = <Widget>[];
        for (int i = 0; i < fields.length; i++) {
          rowChildren.add(Expanded(child: _FieldTile(fields[i])));
          if (i < fields.length - 1) {
            rowChildren.add(const SizedBox(width: 24));
          }
        }
        return Row(children: rowChildren);
      }
      return Column(
        children: fields
            .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _FieldTile(f),
                ))
            .toList(),
      );
    });
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}

class _Field {
  final String label;
  final String value;
  const _Field(this.label, this.value);
}

class _FieldTile extends StatelessWidget {
  final _Field field;
  const _FieldTile(this.field);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(field.value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      );
}