import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

class InternProfile {
  final String name;
  final int internNumber;
  final String program;
  final String school;
  final String specialization;
  final String email;
  final List<String> technicalSkills;
  final List<String> softSkills;
  final Color avatarColor;
  final String initials;

  const InternProfile({
    required this.name,
    required this.internNumber,
    required this.program,
    required this.school,
    required this.specialization,
    required this.email,
    required this.technicalSkills,
    required this.softSkills,
    required this.avatarColor,
    required this.initials,
  });
}

List<InternProfile> get kInterns => [
  const InternProfile(
    name: 'Jamie Reyes',
    internNumber: 1,
    program: 'Bachelor of Science in Computer Science',
    school: 'University of Santo Tomas',
    specialization: 'Web Development',
    email: 'jamie.reyes@email.com',
    technicalSkills: ['Flutter', 'Dart', 'Firebase', 'Git'],
    softSkills: ['Teamwork', 'Communication', 'Adaptable'],
    avatarColor: Color(0xFF7B1A2E),
    initials: 'JR',
  ),
  const InternProfile(
    name: 'Lorraine De Castro',
    internNumber: 2,
    program: 'Bachelor of Science in Information Technology',
    school: 'De La Salle University',
    specialization: 'UI/UX Design',
    email: 'lorraine@gmail.com',
    technicalSkills: ['Figma', 'HTML/CSS', 'React', 'Prototyping'],
    softSkills: ['Creativity', 'Detail-oriented', 'Time management'],
    avatarColor: Color(0xFF4A1040),
    initials: 'LD',
  ),
  const InternProfile(
    name: 'Airra De Castro',
    internNumber: 3,
    program: 'Bachelor of Science in Software Engineering',
    school: 'Ateneo de Manila University',
    specialization: 'Backend Systems',
    email: 'airra@gmail.com',
    technicalSkills: ['Python', 'Django', 'PostgreSQL', 'Docker'],
    softSkills: ['Problem-solving', 'Leadership', 'Critical thinking'],
    avatarColor: Color(0xFF1A1050),
    initials: 'AD',
  ),
  const InternProfile(
    name: 'Alex Santos',
    internNumber: 12,
    program: 'Bachelor of Science in Information System',
    school: 'CARD',
    specialization: 'N/A',
    email: 'alex@gmail.com',
    technicalSkills: ['HTML', 'Python', 'C++'],
    softSkills: ['Attention to detail', 'Adaptability', 'Problem-solving', 'Teamwork'],
    avatarColor: Color(0xFF2A3A1A),
    initials: 'AS',
  ),
  const InternProfile(
    name: 'Joy Mendoza',
    internNumber: 8,
    program: 'Bachelor of Science in Computer Engineering',
    school: 'Mapúa University',
    specialization: 'Embedded Systems',
    email: 'joy.mendoza@email.com',
    technicalSkills: ['C', 'Arduino', 'MATLAB', 'PCB Design'],
    softSkills: ['Analytical thinking', 'Persistence', 'Collaboration'],
    avatarColor: Color(0xFF3A2A10),
    initials: 'JM',
  ),
  const InternProfile(
    name: 'Raven Cruz',
    internNumber: 5,
    program: 'Bachelor of Science in Data Science',
    school: 'University of the Philippines',
    specialization: 'Machine Learning',
    email: 'raven.cruz@email.com',
    technicalSkills: ['Python', 'TensorFlow', 'SQL', 'Tableau'],
    softSkills: ['Curiosity', 'Research', 'Presentation'],
    avatarColor: Color(0xFF0A3A3A),
    initials: 'RC',
  ),
];

class _InternCardFront extends StatelessWidget {
  final InternProfile intern;
  const _InternCardFront({required this.intern});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Hero(
        tag: 'intern-${intern.internNumber}',
        child: Card(
          elevation: 0,
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B1524),
                  Color(0xFF4A0E18),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4A0E18).withOpacity(0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: Text(
                      intern.initials,
                      style: const TextStyle(
                        fontSize: 54, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B1524),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  intern.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Intern ${intern.internNumber}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.8),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 22),
      ),
    );
  }
}

class InternDetailPage extends StatefulWidget {
  final InternProfile intern;
  const InternDetailPage({super.key, required this.intern});

  @override
  State<InternDetailPage> createState() => _InternDetailPageState();
}

class _InternDetailPageState extends State<InternDetailPage> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  final List<DetailStar> _stars = [];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    final rng = math.Random();
    for (int i = 0; i < 160; i++) {
_stars.add(DetailStar(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 1.8 + 0.4,
        opacity: rng.nextDouble() * 0.6 + 0.2,
        speed: rng.nextDouble() * 0.03 + 0.005,
        phase: rng.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final intern = widget.intern;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.3),
                  radius: 1.4,
                  colors: [Color(0xFF3A0810), Color(0xFF130205), Color(0xFF050505)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: AnimatedBuilder(
                animation: _bgController,
                builder: (_, __) => CustomPaint(
                  painter: StarfieldPainter(animValue: _bgController.value, stars: _stars),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 800),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 16),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
                                onPressed: () => Navigator.of(context).pop(),
                                splashRadius: 24,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Hero(
                                  tag: 'intern-${intern.internNumber}',
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F2),
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: Center(
                                      child: Text(
                                        intern.initials,
                                        style: TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                          color: intern.avatarColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  intern.name,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  'Intern #${intern.internNumber}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                _InfoRow(icon: Icons.school, label: 'Program', value: intern.program),
                                _InfoRow(icon: Icons.location_city, label: 'School', value: intern.school),
                                _InfoRow(icon: Icons.work, label: 'Specialization', value: intern.specialization),
                                _InfoRow(icon: Icons.email, label: 'Email', value: intern.email),
                                const SizedBox(height: 24),
                                const Text(
                                  'Technical Skills',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: intern.technicalSkills.map((skill) => _SkillChip(skill)).toList(),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Soft Skills',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: intern.softSkills.map((skill) => _SkillChip(skill)).toList(),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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

class _SkillChip extends StatelessWidget {
  final String skill;
  const _SkillChip(this.skill);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}



class DetailStar {
  final double x, y, size, opacity, speed, phase;
  const DetailStar({
    required this.x,
    required this.y,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.phase,
  });
}

class StarfieldPainter extends CustomPainter {
  final double animValue;
  final List<DetailStar> stars;
  StarfieldPainter({required this.animValue, required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final star in stars) {
      final twinkle = (math.sin((animValue * 2 * math.pi * 1.5) + star.phase) + 1) / 2;
      final alpha = (star.opacity * (0.3 + 0.7 * twinkle)).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(alpha);
      final dx = (star.x * size.width + animValue * size.width * star.speed) % size.width;
      final dy = star.y * size.height;
      if (star.size > 1.5) {
        canvas.drawCircle(
          Offset(dx, dy),
          star.size * 2,
          Paint()
            ..color = Colors.white.withOpacity(alpha * 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
        );
      }
      canvas.drawCircle(Offset(dx, dy), star.size, paint);
    }
  }

  @override
  bool shouldRepaint(StarfieldPainter old) => old.animValue != animValue;
}

void _startAutoScroll() {
  // Timer implementation from user_home_screen
}

void _prev() {
  // Implementation from user_home_screen
}

void _next() {
  // Implementation from user_home_screen
}
