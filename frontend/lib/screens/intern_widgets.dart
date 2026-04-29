import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/api_service.dart';

// ── Brand colors ──────────────────────────────────────────────────────────────
const kBlue = Color(0xFF1E40AF);
const kBlueDark = Color(0xFF1E2A44);
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
    final firstName = (json['first_name'] ?? '').toString().trim();
    final lastName = (json['last_name'] ?? '').toString().trim();
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    List<String> parseStringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String && value.isNotEmpty) {
        return value.split(',').map((s) => s.trim()).toList();
      }
      return [];
    }

    return InternProfile(
      id: json['id'] as int,
      name: fullName.isNotEmpty ? fullName : 'Unnamed Intern',
      internNumber: json['intern_number'] as String? ?? 'N/A',
      program: (json['program'] ?? '').toString().trim().isNotEmpty
          ? json['program']
          : 'N/A',
      school: (json['school'] ?? '').toString().trim().isNotEmpty
          ? json['school']
          : 'N/A',
      specialization:
          (json['specialization'] ?? '').toString().trim().isEmpty ? null : json['specialization'],
      email: json['email'] ?? '',
      technicalSkills: parseStringList(json['technical_skills']),
      softSkills: parseStringList(json['soft_skills']),
      avatarUrl: json['avatar_url'],
      position: (json['position'] ?? '').toString().trim().isEmpty ? null : json['position'],
      department: (json['department'] ?? '').toString().trim().isEmpty ? null : json['department'],
      bio: (json['bio'] ?? '').toString().trim().isEmpty ? null : json['bio'],
      yearLevel: (json['year_level'] ?? '').toString().trim().isEmpty ? null : json['year_level'],
      startDate: (json['start_date'] ?? '').toString().trim().isEmpty ? null : json['start_date'],
      endDate: (json['end_date'] ?? '').toString().trim().isEmpty ? null : json['end_date'],
      githubUrl: (json['git_hub'] ?? '').toString().trim().isEmpty ? null : json['git_hub'],
      linkedInUrl: (json['linked_in'] ?? '').toString().trim().isEmpty ? null : json['linked_in'],
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
        color: const Color(0xFFF2F2F2),
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

  const _InitialsFallback({required this.initials, required this.color, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F2),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
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

    return Scaffold(
      // Detect taps on the entire background to close the page
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Sharp Background Image (No blur)
            Image.asset(
              'assets/images/space_background.png',
              fit: BoxFit.cover,
            ),
            
            // Dark Overlay to make the background blacker/darker
            Container(
              color: Colors.black.withValues(alpha: 0.6),
            ),
            
            // Foreground Content
            SafeArea(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64 : 24, 
                    vertical: 32, 
                  ),
                  // Intercept taps on the card so it doesn't close the page when clicking inside
                  child: GestureDetector(
                    onTap: () {}, 
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            maxWidth: 1100,
                            minHeight: isDesktop ? 750 : 0, 
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF0F172A).withValues(alpha: 0.70),
                                const Color(0xFF1E1B4B).withValues(alpha: 0.60),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              )
                            ]
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min, 
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Dynamic Layout 
                              Padding(
                                padding: const EdgeInsets.all(48),
                                child: isDesktop 
                                    ? _buildDesktopLayout(intern) 
                                    : _buildMobileLayout(intern),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── DESKTOP SPLIT LAYOUT ──
  Widget _buildDesktopLayout(InternProfile intern) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, 
      children: [
        // Left Column (Visual Identity)
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              _buildGlowingAvatar(intern),
              const SizedBox(height: 24),
              if (intern.internNumber != 'N/A') _buildInternBadge(intern.internNumber),
            ],
          ),
        ),
        const SizedBox(width: 56),
        
        // Right Column (Information & Data)
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeaderDetails(intern),
              if (intern.bio != null && intern.bio!.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildBioQuote(intern.bio!),
              ],
              const SizedBox(height: 32),
              _buildDataGrid(intern, isDesktop: true),
              const SizedBox(height: 32),
              _buildSkillsSection(intern),
            ],
          ),
        ),
      ],
    );
  }

  // ── MOBILE VERTICAL LAYOUT ──
  Widget _buildMobileLayout(InternProfile intern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildGlowingAvatar(intern),
        const SizedBox(height: 24),
        if (intern.internNumber != 'N/A') _buildInternBadge(intern.internNumber),
        const SizedBox(height: 32),
        _buildHeaderDetails(intern, isCentered: true),
        if (intern.bio != null && intern.bio!.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildBioQuote(intern.bio!),
        ],
        const SizedBox(height: 32),
        _buildDataGrid(intern, isDesktop: false),
        const SizedBox(height: 32),
        _buildSkillsSection(intern),
      ],
    );
  }

  // ── COMPONENT WIDGETS ──

  Widget _buildGlowingAvatar(InternProfile intern) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [kSpaceAccent, kBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: kSpaceAccent.withValues(alpha: 0.4),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Hero(
        tag: 'intern-${intern.id}',
        child: InternAvatar(
          intern: intern,
          size: 200, 
          borderRadius: 150, 
          fontSize: 64,
        ),
      ),
    );
  }

  Widget _buildInternBadge(String number) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: kBlueLight.withValues(alpha: 0.15),
        border: Border.all(color: kBlueLight.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars, color: kBlueLight, size: 16),
          const SizedBox(width: 8),
          Text(
            'INTERN #$number',
            style: const TextStyle(
              color: kBlueLight,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderDetails(InternProfile intern, {bool isCentered = false}) {
    return Column(
      crossAxisAlignment: isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            intern.name,
            style: const TextStyle(
              fontSize: 38,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: isCentered ? TextAlign.center : TextAlign.left,
          ),
        ),
        const SizedBox(height: 8),
        if (intern.position != null || intern.department != null)
          Text(
            '${intern.position ?? 'Intern'}  •  ${intern.department ?? 'Dept N/A'}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.5,
            ),
            textAlign: isCentered ? TextAlign.center : TextAlign.left,
          ),
      ],
    );
  }

  Widget _buildBioQuote(String bio) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: kSpaceAccent.withValues(alpha: 0.8), width: 4)),
      ),
      child: Text(
        '"$bio"',
        style: TextStyle(
          fontSize: 14,
          fontStyle: FontStyle.italic,
          color: Colors.white.withValues(alpha: 0.8),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildDataGrid(InternProfile intern, {required bool isDesktop}) {
    final academicModule = _buildDataModule(
      title: 'ACADEMIC RECORD',
      icon: Icons.biotech,
      rows: [
        _InfoRow(icon: Icons.account_balance, label: 'Institution', value: intern.school.isNotEmpty ? intern.school : 'N/A'),
        _InfoRow(icon: Icons.menu_book, label: 'Program', value: intern.program.isNotEmpty ? intern.program : 'N/A'),
        if (intern.specialization != null && intern.specialization!.isNotEmpty)
          _InfoRow(icon: Icons.psychology, label: 'Specialization', value: intern.specialization!),
        if (intern.yearLevel != null && intern.yearLevel!.isNotEmpty)
          _InfoRow(icon: Icons.timeline, label: 'Year Level', value: intern.yearLevel!),
      ],
    );

    final deploymentModule = _buildDataModule(
      title: 'DEPLOYMENT DATA',
      icon: Icons.radar,
      rows: [
        if (intern.department != null && intern.department!.isNotEmpty)
          _InfoRow(icon: Icons.account_tree, label: 'Department', value: intern.department!),
        if (intern.position != null && intern.position!.isNotEmpty)
          _InfoRow(icon: Icons.badge, label: 'Designation', value: intern.position!),
        if (intern.startDate != null && intern.startDate!.isNotEmpty)
          _InfoRow(icon: Icons.flight_takeoff, label: 'Start Date', value: intern.startDate!),
        if (intern.endDate != null && intern.endDate!.isNotEmpty)
          _InfoRow(icon: Icons.flight_land, label: 'End Date', value: intern.endDate!),
      ],
    );

    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: academicModule),
            const SizedBox(width: 24),
            Expanded(child: deploymentModule),
          ],
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          academicModule,
          const SizedBox(height: 24),
          deploymentModule,
        ],
      );
    }
  }

  Widget _buildDataModule({required String title, required IconData icon, required List<Widget> rows}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: kSpaceAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: kSpaceAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildSkillsSection(InternProfile intern) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intern.technicalSkills.isNotEmpty) ...[
          const Text('TECHNICAL SKILLS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: intern.technicalSkills.map((s) => _SkillChip(s, isTech: true)).toList()),
          const SizedBox(height: 24),
        ],
        if (intern.softSkills.isNotEmpty) ...[
          const Text('SOFT SKILLS', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: intern.softSkills.map((s) => _SkillChip(s, isTech: false)).toList()),
        ],
      ],
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4), fontWeight: FontWeight.w600, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500, height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String skill;
  final bool isTech;
  const _SkillChip(this.skill, {required this.isTech});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isTech ? kBlueDark.withValues(alpha: 0.5) : const Color(0xFF334155).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isTech ? kBlueLight.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          color: isTech ? kBlueLight : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}