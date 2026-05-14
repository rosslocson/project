import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/api_service.dart';
import '../widgets/app_background.dart';

// ── Brand colors ──────────────────────────────────────────────────────────────
const kBlue = Color(0xFF1E40AF);
const kBlueDark = Color(0xFF0F172A);
const kBlueLight = Color(0xFF3B82F6);
const kSpaceAccent = Color(0xFF8B5CF6);

class InternProfile {
  final int id;
  final String name;
  final String internNumber;
  final String program;
  final String school;
  final String? specialization;
  final String email;
  final List<String> technicalSkills;
  final List<String> softSkills;
  final String? avatarUrl;
  final String? position;
  final String? department;
  final String? bio;
  final String? yearLevel;
  final String? startDate;
  final String? endDate;
  final String? githubUrl;
  final String? linkedInUrl;

  const InternProfile({
    required this.id,
    required this.name,
    required this.internNumber,
    required this.program,
    required this.school,
    this.specialization,
    required this.email,
    required this.technicalSkills,
    required this.softSkills,
    this.avatarUrl,
    this.position,
    this.department,
    this.bio,
    this.yearLevel,
    this.startDate,
    this.endDate,
    this.githubUrl,
    this.linkedInUrl,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get avatarColor {
    const colors = [
      Color(0xFF7B1A2E),
      Color(0xFF4A1040),
      Color(0xFF1A1050),
      Color(0xFF2A3A1A),
      Color(0xFF3A2A10),
      Color(0xFF0A3A3A),
    ];
    return colors[id % colors.length];
  }

  factory InternProfile.fromJson(Map<String, dynamic> json) {
    // Robust parser to ensure no type-casting errors cause data to evaluate to null
    String? parseString(dynamic value) {
      if (value == null) return null;
      final str = value.toString().trim();
      if (str.isEmpty || str.toLowerCase() == 'null') return null;
      return str;
    }

    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    final firstName = parseString(json['first_name']) ?? '';
    final lastName = parseString(json['last_name']) ?? '';
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    return InternProfile(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: fullName.isNotEmpty ? fullName : 'Unnamed Intern',
      internNumber: parseString(json['intern_number']) ?? 'N/A',
      program: parseString(json['program']) ?? 'N/A',
      school: parseString(json['school']) ?? 'N/A',
      specialization: parseString(json['specialization']),
      email: parseString(json['email']) ?? '',
      technicalSkills: parseStringList(json['technical_skills']),
      softSkills: parseStringList(json['soft_skills']),
      avatarUrl: parseString(json['avatar_url']),
      position: parseString(json['position']),
      department: parseString(json['department']),
      bio: parseString(json['bio']),
      yearLevel: parseString(json['year_level']),
      startDate: parseString(json['start_date']), // Safely parsed now
      endDate: parseString(json['end_date']),     // Safely parsed now
      githubUrl: parseString(json['git_hub']),
      linkedInUrl: parseString(json['linked_in']),
    );
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────

class InternAvatar extends StatelessWidget {
  final InternProfile intern;
  final double size;
  final double borderRadius;
  final double fontSize;

  const InternAvatar({
    super.key,
    required this.intern,
    this.size = 140,
    this.borderRadius = 32,
    this.fontSize = 54,
  });

  String? get _resolvedAvatarUrl {
    final raw = intern.avatarUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

    final serverRoot = ApiService.baseUrl.replaceAll(RegExp(r'/api/?$'), '');
    final cleanRaw = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$serverRoot/$cleanRaw';
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedAvatarUrl;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialsFallback(
                initials: intern.initials,
                color: intern.avatarColor,
                fontSize: fontSize,
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    color: kBlueLight,
                    strokeWidth: 2,
                  ),
                );
              },
            )
          : _InitialsFallback(
              initials: intern.initials,
              color: intern.avatarColor,
              fontSize: fontSize,
            ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final String initials;
  final Color color;
  final double fontSize;

  const _InitialsFallback(
      {required this.initials, required this.color, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
              fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

// ── Detail Page ───────────────────────────────────────────────────────────────

class InternDetailPage extends StatelessWidget {
  final InternProfile intern;

  const InternDetailPage({super.key, required this.intern});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 850;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBgColor = isDark
        ? const Color(0xFF0B1021).withValues(alpha: 0.65)
        : const Color(0xFFFFFFFF).withValues(alpha: 0.85);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: AppBackground(
          child: Container(
            color: Colors.black.withValues(alpha: isDark ? 0.8 : 0.3),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GestureDetector(
                    onTap: () {}, // Prevent tap from closing card
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                        child: Container(
                          // STRICT CONSISTENT SIZING
                          width: isDesktop ? 1050 : 450,
                          height: isDesktop ? 650 : 850,
                          decoration: BoxDecoration(
                            color: cardBgColor,
                            borderRadius: BorderRadius.circular(48),
                            border: Border.all(color: borderColor, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                                blurRadius: 60,
                                offset: const Offset(0, 30),
                              )
                            ],
                          ),
                          child: isDesktop
                              ? _buildDesktopLayout(intern, isDark)
                              : _buildMobileLayout(intern, isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── DESKTOP SPLIT LAYOUT (Editorial Style) ──
  Widget _buildDesktopLayout(InternProfile intern, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // LEFT PANE: Identity Focus
        Container(
          width: 420,
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.02)
                : Colors.black.withValues(alpha: 0.02),
            border: Border(
              right: BorderSide(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          child: _buildIdentityPane(intern, isDark),
        ),

        // RIGHT PANE: Flowing Data
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
            child: RawScrollbar(
              thumbColor: isDark 
                  ? Colors.white.withValues(alpha: 0.1) 
                  : Colors.black.withValues(alpha: 0.1),
              radius: const Radius.circular(8),
              thickness: 4,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Academic Profile', isDark),
                    const SizedBox(height: 24),
                    _buildDataGridRow([
                      _EditorialDataNode(label: 'Institution', value: intern.school, isDark: isDark),
                      _EditorialDataNode(label: 'Program', value: intern.program, isDark: isDark),
                    ]),
                    const SizedBox(height: 20),
                    _buildDataGridRow([
                      _EditorialDataNode(label: 'Specialization', value: intern.specialization ?? 'N/A', isDark: isDark),
                      _EditorialDataNode(label: 'Year Level', value: intern.yearLevel ?? 'N/A', isDark: isDark),
                    ]),
                    
                    const SizedBox(height: 48),
                    
                    _buildSectionHeader('Deployment Data', isDark),
                    const SizedBox(height: 24),
                    _buildDataGridRow([
                      _EditorialDataNode(label: 'Department', value: intern.department ?? 'N/A', isDark: isDark),
                      // Hardcoded as Intern
                      _EditorialDataNode(label: 'Designation', value: 'Intern', isDark: isDark),
                    ]),
                    const SizedBox(height: 20),
                    // Start and End Dates Explicitly Listed Here
                    _buildDataGridRow([
                      _EditorialDataNode(label: 'Start Date', value: intern.startDate ?? 'TBA', isDark: isDark),
                      _EditorialDataNode(label: 'End Date', value: intern.endDate ?? 'TBA', isDark: isDark),
                    ]),

                    const SizedBox(height: 48),

                    _buildSectionHeader('Competencies', isDark),
                    const SizedBox(height: 24),
                    _buildSkillsSection(intern, isDark),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── MOBILE LAYOUT (Vertical Flow) ──
  Widget _buildMobileLayout(InternProfile intern, bool isDark) {
    return RawScrollbar(
      thumbColor: isDark 
          ? Colors.white.withValues(alpha: 0.1) 
          : Colors.black.withValues(alpha: 0.1),
      radius: const Radius.circular(8),
      thickness: 4,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildIdentityPane(intern, isDark),
            Container(
              height: 1,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.05) 
                  : Colors.black.withValues(alpha: 0.05),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Academic Profile', isDark),
                  const SizedBox(height: 20),
                  _EditorialDataNode(label: 'Institution', value: intern.school, isDark: isDark),
                  const SizedBox(height: 16),
                  _EditorialDataNode(label: 'Program', value: intern.program, isDark: isDark),
                  const SizedBox(height: 16),
                  _EditorialDataNode(label: 'Specialization', value: intern.specialization ?? 'N/A', isDark: isDark),
                  const SizedBox(height: 16),
                  _EditorialDataNode(label: 'Year Level', value: intern.yearLevel ?? 'N/A', isDark: isDark),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('Deployment Data', isDark),
                  const SizedBox(height: 20),
                  _EditorialDataNode(label: 'Department', value: intern.department ?? 'N/A', isDark: isDark),
                  const SizedBox(height: 16),
                  _EditorialDataNode(label: 'Designation', value: 'Intern', isDark: isDark),
                  const SizedBox(height: 16),
                  _EditorialDataNode(label: 'Start Date', value: intern.startDate ?? 'TBA', isDark: isDark),
                  const SizedBox(height: 16),
                  _EditorialDataNode(label: 'End Date', value: intern.endDate ?? 'TBA', isDark: isDark),
                  
                  const SizedBox(height: 40),
                  
                  _buildSectionHeader('Competencies', isDark),
                  const SizedBox(height: 20),
                  _buildSkillsSection(intern, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── IDENTITY PANE ──
  Widget _buildIdentityPane(InternProfile intern, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Avatar Border Restored
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDark 
                      ? [kSpaceAccent, kBlueLight] 
                      : [kBlue, kSpaceAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? kSpaceAccent : kBlue).withValues(alpha: 0.35),
                    blurRadius: 35,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Hero(
                tag: 'intern-${intern.id}',
                child: InternAvatar(
                  intern: intern,
                  size: 210, // Adjusted slightly so bio & links fit perfectly
                  borderRadius: 200, 
                  fontSize: 70,
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Typography Focus: Name
            Text(
              intern.name,
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.1,
                letterSpacing: -1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Clean Pill Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'INTERN',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.2) 
                          : Colors.black.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    'ID: ${intern.internNumber != 'N/A' ? intern.internNumber : 'TBA'}',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            // Floating Quote / Bio (if exists)
            if (intern.bio != null && intern.bio!.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text(
                '"${intern.bio}"',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.6) 
                      : const Color(0xFF475569),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Digital Presence / Social Links
            if ((intern.linkedInUrl?.isNotEmpty ?? false) || (intern.githubUrl?.isNotEmpty ?? false)) ...[
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (intern.linkedInUrl?.isNotEmpty ?? false)
                    _SocialChip(icon: Icons.work_outline, label: 'LinkedIn', isDark: isDark),
                  if ((intern.linkedInUrl?.isNotEmpty ?? false) && (intern.githubUrl?.isNotEmpty ?? false))
                    const SizedBox(width: 12),
                  if (intern.githubUrl?.isNotEmpty ?? false)
                    _SocialChip(icon: Icons.code, label: 'GitHub', isDark: isDark),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── HELPER WIDGETS ──

  Widget _buildSectionHeader(String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300, // Elegant thin font for headers
            letterSpacing: 0.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 2,
          color: isDark ? kSpaceAccent : kBlue,
        ),
      ],
    );
  }

  Widget _buildDataGridRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children.map((child) => Expanded(child: child)).toList(),
    );
  }

  Widget _buildSkillsSection(InternProfile intern, bool isDark) {
    if (intern.technicalSkills.isEmpty && intern.softSkills.isEmpty) {
      return Text(
        'No competencies logged.',
        style: TextStyle(
          color: isDark ? Colors.white30 : Colors.black26,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intern.technicalSkills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: intern.technicalSkills
                .map((s) => _SoftChip(s, isTech: true, isDark: isDark))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (intern.softSkills.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: intern.softSkills
                .map((s) => _SoftChip(s, isTech: false, isDark: isDark))
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ── Shared Sub-Widgets (Editorial Style) ──────────────────────────────────────

class _EditorialDataNode extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _EditorialDataNode({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value.trim().isEmpty ? 'N/A' : value;

    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.4) 
                  : Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayValue,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  final String skill;
  final bool isTech;
  final bool isDark;

  const _SoftChip(this.skill, {required this.isTech, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final techBgDark = kSpaceAccent.withValues(alpha: 0.15);
    final techBgLight = kBlue.withValues(alpha: 0.08);
    
    final softBgDark = Colors.white.withValues(alpha: 0.05);
    final softBgLight = Colors.black.withValues(alpha: 0.04);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isTech ? (isDark ? techBgDark : techBgLight) : (isDark ? softBgDark : softBgLight),
        borderRadius: BorderRadius.circular(20), 
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: isTech
              ? (isDark ? const Color(0xFFC4B5FD) : kBlue)
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _SocialChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _SocialChip({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white70 : Colors.black87),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}