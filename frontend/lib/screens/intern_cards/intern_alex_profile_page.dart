import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import 'dart:math';
import '../intern_cards.dart';
import '../../widgets/app_background.dart';

// ── ALEX LLANZA DEEP SPACE PROFILE PAGE ──────────────────────────────────────

class AlexProfilePage extends StatefulWidget {
  final InternProfile intern;

  const AlexProfilePage({super.key, required this.intern});

  @override
  State<AlexProfilePage> createState() => _AlexProfilePageState();
}

class _AlexProfilePageState extends State<AlexProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isFrontVisible = true;

  static const String _fallbackUrl = 'https://yourcompanysite.com';

  @override
  void initState() {
    super.initState();
    // Smooth, cinematic card flip
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleCardFlip() {
    if (_isFrontVisible) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFrontVisible = !_isFrontVisible;
    });
  }

  Future<void> _launch(String? url) async {
    final target = (url == null || url.isEmpty) ? _fallbackUrl : url;
    final uri = Uri.parse(target);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(), 
        behavior: HitTestBehavior.opaque,
        child: AppBackground(
          child: Container(
            color: isLightMode 
                ? Colors.black.withValues(alpha: 0.15) 
                : Colors.black.withValues(alpha: 0.3),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64 : 16,
                    vertical: 32,
                  ),
                  child: AnimatedBuilder(
                    animation: _flipController,
                    builder: (context, child) {
                      final angle = _flipController.value * pi;
                      final isFrontSide = angle < pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: GestureDetector(
                          onTap: _toggleCardFlip,
                          child: _buildCosmicCard(isDesktop, isFrontSide, isLightMode),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── CORE CARD STRUCTURE ────────────────────────────────────────────────────
  Widget _buildCosmicCard(bool isDesktop, bool isFrontSide, bool isLightMode) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1150, minHeight: 600),
      decoration: BoxDecoration(
        color: isLightMode ? Colors.white : null,
        borderRadius: BorderRadius.circular(32),
        image: isLightMode 
            ? null 
            : const DecorationImage(
                image: AssetImage('images/alex_blue.jpg'),
                fit: BoxFit.cover,
              ),
        border: Border.all(
          color: isLightMode 
              ? Colors.grey.withValues(alpha: 0.2)
              : const Color(0xFF3B82F6).withValues(alpha: 0.3), 
          width: 1.5
        ),
        boxShadow: [
          BoxShadow(
            color: isLightMode 
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, 20),
          ),
          if (!isLightMode)
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              blurRadius: 80,
              spreadRadius: -10,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          color: isLightMode 
              ? Colors.transparent 
              : const Color(0xFF0B0E14).withValues(alpha: 0.65),
          child: Stack(
            children: [
              // Reverse the content mirror effect from the card flip
              Transform(
                alignment: Alignment.center,
                transform: isFrontSide ? Matrix4.identity() : Matrix4.rotationY(pi),
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  // UNIFIED LAYOUT: Ensures the avatar never moves
                  child: _buildCardContent(isDesktop, isFrontSide, isLightMode),
                ),
              ),
              
              // Animated Flip Hint at bottom right
              Positioned(
                bottom: 20,
                right: 30,
                child: Transform(
                  alignment: Alignment.center,
                  transform: isFrontSide ? Matrix4.identity() : Matrix4.rotationY(pi),
                  child: Row(
                    children: [
                      Text(
                        "Tap anywhere to flip",
                        style: TextStyle(
                          color: isLightMode 
                              ? const Color(0xFF6B21A8).withValues(alpha: 0.7) 
                              : const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.change_circle_outlined,
                        color: isLightMode 
                            ? const Color(0xFF6B21A8).withValues(alpha: 0.7)
                            : const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                        size: 16,
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── UNIFIED LAYOUT: AVATAR + PANELS STACK ──────────────────────────────────
  Widget _buildCardContent(bool isDesktop, bool isFrontSide, bool isLightMode) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 4, child: _buildAvatarIdentity(isLightMode)),
          const SizedBox(width: 40),
          Expanded(flex: 6, child: _buildPanelsStack(isFrontSide, isLightMode)),
        ],
      );
    }

    return Column(
      children: [
        _buildAvatarIdentity(isLightMode),
        const SizedBox(height: 40),
        _buildPanelsStack(isFrontSide, isLightMode),
      ],
    );
  }

  // ── PANELS STACK: PREVENTS JUMPING BY LOCKING TO MAX HEIGHT ────────────────
  Widget _buildPanelsStack(bool isFrontSide, bool isLightMode) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // BACK SIDE (Skills)
        Visibility(
          visible: !isFrontSide,
          maintainSize: true, 
          maintainAnimation: true,
          maintainState: true,
          child: _buildSkillsPanels(isLightMode),
        ),
        // FRONT SIDE (Data)
        Visibility(
          visible: isFrontSide,
          maintainSize: true, 
          maintainAnimation: true,
          maintainState: true,
          child: _buildDataPanels(isLightMode),
        ),
      ],
    );
  }

  // ── CREATIVE AVATAR SECTION ────────────────────────────────────────────────
  Widget _buildAvatarIdentity(bool isLightMode) {
    const double avatarSize = 210;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: avatarSize + 16,
          height: avatarSize + 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFF2DD4BF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: -10,
                offset: const Offset(10, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLightMode ? Colors.white : const Color(0xFF0B0E14), 
              ),
              child: ClipOval(
                child: InternAvatar(
                  intern: widget.intern,
                  size: avatarSize,
                  borderRadius: avatarSize / 2,
                  fontSize: 42, 
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          widget.intern.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isLightMode ? const Color(0xFF111827) : Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isLightMode 
                ? const Color(0xFFF3E8FF) 
                : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isLightMode 
                  ? const Color(0xFFD8B4FE) 
                  : const Color(0xFF8B5CF6).withValues(alpha: 0.4)
            ),
          ),
          child: Text(
            widget.intern.internNumber != 'N/A' ? 'ID: #${widget.intern.internNumber}' : 'SYSTEM APPRENTICE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
              color: isLightMode ? const Color(0xFF6B21A8) : const Color(0xFFC4B5FD), 
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialButton(icon: Icons.terminal_rounded, onTap: () => _launch(widget.intern.githubUrl)),
            const SizedBox(width: 16),
            _SocialButton(icon: Icons.link_rounded, onTap: () => _launch(widget.intern.linkedInUrl)),
          ],
        ),
      ],
    );
  }

  // ── FROSTED GLASS DATA PANELS (FRONT) ──────────────────────────────────────
  Widget _buildDataPanels(bool isLightMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUniqueGlassCard(
          isLightMode: isLightMode,
          title: "Academic Profile",
          child: Column(
            children: [
              _DetailGridRow(
                label1: 'INSTITUTION',
                value1: widget.intern.school.isNotEmpty ? widget.intern.school : 'CARD-MRI Development Institute, Inc.',
                label2: 'PROGRAM',
                value2: widget.intern.program.isNotEmpty ? widget.intern.program : 'Bachelor of Science in Information Systems',
              ),
              const SizedBox(height: 36),
              _DetailGridRow(
                label1: 'SPECIALIZATION',
                value1: widget.intern.specialization?.isNotEmpty == true ? widget.intern.specialization! : 'N/A',
                label2: 'YEAR LEVEL',
                value2: '4th Year', 
              ),
            ],
          ),
        ),
        const SizedBox(height: 32), 
        _buildUniqueGlassCard(
          isLightMode: isLightMode,
          title: "Deployment Data",
          child: Column(
            children: [
              _DetailGridRow(
                label1: 'DEPARTMENT',
                value1: widget.intern.department?.isNotEmpty == true ? widget.intern.department! : 'Development Department',
                label2: 'DESIGNATION',
                value2: widget.intern.position?.isNotEmpty == true ? widget.intern.position! : 'Intern',
              ),
              const SizedBox(height: 36), 
              const _DetailGridRow(
                label1: 'START DATE',
                value1: 'Feb 18, 2026',
                label2: 'END DATE',
                value2: 'May 15, 2026',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── FROSTED GLASS SKILL PANELS (BACK) ──────────────────────────────────────
  Widget _buildSkillsPanels(bool isLightMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildUniqueGlassCard(
          isLightMode: isLightMode,
          title: "Competencies",
          child: Container(
            constraints: const BoxConstraints(minHeight: 60), 
            alignment: Alignment.topLeft,
            child: widget.intern.technicalSkills.isNotEmpty
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.intern.technicalSkills
                        .asMap()
                        .entries
                        .map((e) => _CosmicBadge(label: e.value))
                        .toList(),
                  )
                : Text(
                    'No structural technical skills configured.',
                    style: TextStyle(
                      fontSize: 12, 
                      color: isLightMode ? Colors.black54 : Colors.white.withValues(alpha: 0.5), 
                      fontStyle: FontStyle.italic
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 32), 
        _buildUniqueGlassCard(
          isLightMode: isLightMode,
          title: "Interpersonal Skills",
          child: Container(
            constraints: const BoxConstraints(minHeight: 60), 
            alignment: Alignment.topLeft,
            child: widget.intern.softSkills.isNotEmpty
                ? Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: widget.intern.softSkills
                        .asMap()
                        .entries
                        .map((e) => _CosmicBadge(label: e.value))
                        .toList(),
                  )
                : Text(
                    'No baseline interactive soft competencies configured.',
                    style: TextStyle(
                      fontSize: 12, 
                      color: isLightMode ? Colors.black54 : Colors.white.withValues(alpha: 0.5), 
                      fontStyle: FontStyle.italic
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ── UNIQUE SCIFI GLASSMORPHISM CARD ────────────────────────────────────────
  Widget _buildUniqueGlassCard({required String title, IconData? icon, required Widget child, required bool isLightMode}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16), 
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 36), 
          decoration: BoxDecoration(
            color: isLightMode 
                ? const Color(0xFFF8FAFC).withValues(alpha: 0.8) 
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isLightMode 
                  ? Colors.grey.withValues(alpha: 0.2) 
                  : Colors.white.withValues(alpha: 0.1), 
              width: 1.0
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: isLightMode ? const Color(0xFF111827) : Colors.white, size: 22),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14, 
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isLightMode ? const Color(0xFF111827) : Colors.white, 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(width: 48, height: 3, color: const Color(0xFF8B5CF6)),
              const SizedBox(height: 28), 
              child,
            ],
          ),
        ),
      ),
    );
  }
}

// ── SUB-COMPONENTS ───────────────────────────────────────────────────────────

class _DetailGridRow extends StatelessWidget {
  final String label1;
  final String value1;
  final String label2;
  final String value2;

  const _DetailGridRow({
    required this.label1,
    required this.value1,
    required this.label2,
    required this.value2,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _DetailItem(label: label1, value: value1),
        ),
        const SizedBox(width: 16), 
        Expanded(
          child: _DetailItem(label: label2, value: value2),
        ),
      ],
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.bold, 
            letterSpacing: 1.5, 
            color: isLightMode ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)
          ),
        ),
        const SizedBox(height: 8), 
        Text(
          value, 
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w500, 
            color: isLightMode ? const Color(0xFF111827) : Colors.white,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}


class _SocialButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SocialButton({required this.icon, required this.onTap});

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150), 
          width: 48,  
          height: 48,
          decoration: BoxDecoration(
            color: _isHovered 
                ? (isLightMode ? const Color(0xFFF3E8FF) : Colors.white.withValues(alpha: 0.1)) 
                : (isLightMode ? Colors.transparent : Colors.white.withValues(alpha: 0.05)),
            shape: BoxShape.circle,
            border: Border.all(
              color: _isHovered 
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.8) 
                  : (isLightMode ? Colors.grey.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.3)),
              width: 1, 
            ),
            boxShadow: _isHovered 
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), 
                      blurRadius: 8, 
                      spreadRadius: 1
                    )
                  ]
                : [],
          ),
          child: Icon(
            widget.icon, 
            size: 22, 
            color: _isHovered 
                ? (isLightMode ? const Color(0xFF6B21A8) : Colors.white)
                : (isLightMode ? const Color(0xFF4B5563) : Colors.white.withValues(alpha: 0.8))
          ),
        ),
      ),
    );
  }
}


class _CosmicBadge extends StatefulWidget {
  final String label;

  const _CosmicBadge({required this.label});

  @override
  State<_CosmicBadge> createState() => _CosmicBadgeState();
}

class _CosmicBadgeState extends State<_CosmicBadge> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLightMode = Theme.of(context).brightness == Brightness.light;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        decoration: BoxDecoration(
          color: isLightMode 
              ? (_isHovered ? const Color(0xFFE9D5FF) : const Color(0xFFF3E8FF))
              : const Color(0xFF1E1133).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24), 
          border: Border.all(
            color: isLightMode
                ? const Color(0xFFD8B4FE).withValues(alpha: _isHovered ? 0.9 : 0.6)
                : const Color(0xFF8B5CF6).withValues(alpha: _isHovered ? 0.9 : 0.3), 
            width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: isLightMode 
                  ? const Color(0xFFC084FC).withValues(alpha: _isHovered ? 0.2 : 0.0)
                  : const Color(0xFF8B5CF6).withValues(alpha: _isHovered ? 0.4 : 0.0),
              blurRadius: _isHovered ? 12 : 0,
              spreadRadius: _isHovered ? 2 : 0,
            )
          ],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isLightMode ? const Color(0xFF581C87) : const Color(0xFFD8B4FE),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}