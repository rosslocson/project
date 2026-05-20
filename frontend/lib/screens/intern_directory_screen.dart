import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../providers/theme_provider.dart';
import 'intern_cards.dart';

class InternDirectoryScreen extends StatefulWidget {
  const InternDirectoryScreen({super.key});

  @override
  State<InternDirectoryScreen> createState() => _InternDirectoryScreenState();
}

class _InternDirectoryScreenState extends State<InternDirectoryScreen> with SingleTickerProviderStateMixin {
  List<InternProfile> _interns = [];
  List<InternProfile> _filteredInterns = [];
  bool _loading = true;
  String? _error;
  
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  final TransformationController _transformationController = TransformationController();
  late AnimationController _animController;
  late Animation<Matrix4> _mapAnimation;

  final double _perspectiveRatio = 0.35; 
  double _canvasWidth = 4000.0;
  double _canvasHeight = 2800.0;

  final List<double> _orbitRadiiX = [450.0, 900.0, 1400.0, 2000.0, 2650.0];
  final List<int> _orbitCapacities = [5, 10, 18, 30, 45];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _searchController.addListener(_onSearchChanged);
    _fetchInterns();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchInterns() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await ApiService.getInterns();
    if (!mounted) return;

    if (res['ok'] == true) {
      final raw = res['users'] ?? res['interns'] ?? res['data'] ?? [];
      final List<InternProfile> loaded = (raw as List)
          .map((j) => InternProfile.fromJson(j as Map<String, dynamic>))
          .toList();

      setState(() {
        loaded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _interns = loaded;
        _filteredInterns = loaded;
        if (_interns.length > 108) {
          _orbitRadiiX.add(2700.0);
          _orbitCapacities.add(60);
          _canvasWidth = 5500.0;
          _canvasHeight = 3500.0;
        }
        _loading = false;
      });
      
      WidgetsBinding.instance.addPostFrameCallback((_) => _recenterMap(animated: false));
    } else {
      setState(() {
        _error = res['error'] ?? 'Failed to load interns';
        _loading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredInterns = _interns;
      } else {
        _filteredInterns = _interns.where((intern) {
          final nameMatch = intern.name.toLowerCase().contains(query);
          final numberMatch = intern.internNumber.toLowerCase().contains(query);
          final schoolMatch = intern.school.toLowerCase().contains(query); 

          return nameMatch || numberMatch || schoolMatch;
        }).toList();
      }
    });
  }

  void _recenterMap({bool animated = true}) {
    final Size screenSize = MediaQuery.of(context).size;
    double targetScale = screenSize.width > 800 ? 0.55 : 0.3; 
    
    final double offsetX = (_canvasWidth * targetScale - screenSize.width) / 2;
    final double offsetY = (_canvasHeight * targetScale - screenSize.height) / 2;
    
    final Matrix4 targetMatrix = Matrix4.identity()
      ..translate(-offsetX, -offsetY)
      ..scale(targetScale);

    if (animated) {
      _mapAnimation = Matrix4Tween(
        begin: _transformationController.value,
        end: targetMatrix,
      ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOutQuart));
      
      _mapAnimation.addListener(() {
        _transformationController.value = _mapAnimation.value;
      });
      _animController.forward(from: 0);
    } else {
      _transformationController.value = targetMatrix;
    }
  }

  // DYNAMIC SCALING LOGIC
  // Calculates size multiplier based on current number of visible users
  double get _currentScaleFactor {
    int count = _filteredInterns.length;
    if (count == 0) return 1.0;
    if (count <= 10) return 1.5;   // Very few users -> Much larger
    if (count <= 25) return 1.25;  // Few users -> Slightly larger
    if (count <= 50) return 1.0;   // Normal amount -> Base size
    if (count <= 80) return 0.85;  // Many users -> Slightly smaller
    return 0.7;                    // Crowded -> Smallest size
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color headingColor = isDark ? Colors.white : const Color(0xFF00022E);
    const Color accentColor = Color(0xFF6366F1);
    final Color bgColor = isDark ? const Color(0xFF02030A) : Colors.white;
    final Color orbitColor = isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFF00022E).withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: isDark 
                  ? [const Color(0xFF0A0C1B), const Color(0xFF02030A)]
                  : [const Color(0xFFF8FAFC), Colors.white],
              ),
            ),
          ),

          if (!_loading && _error == null)
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.1, 
              maxScale: 1.5,
              constrained: false,
              child: SizedBox(
                width: _canvasWidth,
                height: _canvasHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: Size(_canvasWidth, _canvasHeight),
                      painter: OrbitRingsPainter(
                        radiiX: _orbitRadiiX,
                        perspectiveRatio: _perspectiveRatio,
                        color: orbitColor,
                      ),
                    ),
                    Positioned(
                      left: _canvasWidth / 2 - 250,
                      top: _canvasHeight / 2 - 250,
                      child: CentralSun(isDark: isDark),
                    ),
                    ..._buildPlanetarySystem(isDark, headingColor, accentColor),
                  ],
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDark, headingColor, accentColor),
                if (_loading) 
                  const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))),
                if (_error != null) 
                  Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))),
                const Spacer(),
                if (!_loading && _error == null)
                  _buildFocusButton(isDark, headingColor, accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color headingColor, Color accentColor) {
    final Color searchBg = isDark ? const Color(0xFF141526).withValues(alpha: 0.9) : const Color(0xFFF3F4F6);

    return PointerInterceptor(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SYSTEM DIRECTORY',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4.0,
                  ),
                ),
                Text(
                  'Orbital View',
                  style: TextStyle(
                    color: headingColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: headingColor),
                  onPressed: () => Navigator.canPop(context) ? Navigator.pop(context) : context.go('/dashboard'),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: _isSearching ? 260 : 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isSearching ? searchBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _isSearching ? accentColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_isSearching)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  cursorColor: accentColor,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black, 
                                    fontSize: 14,
                                    decoration: TextDecoration.none,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search...',
                                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 14),
                                    border: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                            ),
                          IconButton(
                            icon: Icon(_isSearching ? Icons.close : Icons.search, color: headingColor),
                            onPressed: () {
                              setState(() {
                                if (_isSearching) {
                                  _isSearching = false;
                                  _searchController.clear();
                                  _searchFocusNode.unfocus();
                                } else {
                                  _isSearching = true;
                                  _searchFocusNode.requestFocus();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: isDark ? 'Light Mode' : 'Dark Mode',
                      waitDuration: const Duration(milliseconds: 300),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                        splashRadius: 18,
                        hoverColor: isDark ? Colors.white24 : Colors.black12,
                        icon: Icon(
                          isDark
                              ? Icons.wb_sunny_outlined
                              : Icons.nightlight_round_outlined,
                          color: headingColor,
                          size: 20,
                        ),
                        onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusButton(bool isDark, Color headingColor, Color accentColor) {
    return PointerInterceptor(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30.0),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF141526).withValues(alpha: 0.9) : const Color(0xFF00022E),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(color: accentColor, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: _recenterMap,
          icon: Icon(Icons.adjust, size: 18, color: isDark ? accentColor : Colors.white),
          label: const Text('Focus Core', style: TextStyle(letterSpacing: 1.0)),
        ),
      ),
    );
  }

  List<Widget> _buildPlanetarySystem(bool isDark, Color headingColor, Color accentColor) {
    List<Widget> planets = [];
    final double centerX = _canvasWidth / 2;
    final double centerY = _canvasHeight / 2;
    
    // Retrieve the calculated scale factor based on current users
    final double scaleFactor = _currentScaleFactor;
    int currentInternIndex = 0;

    for (int ringIndex = 0; ringIndex < _orbitRadiiX.length; ringIndex++) {
      if (currentInternIndex >= _filteredInterns.length) break;
      double radiusX = _orbitRadiiX[ringIndex];
      double radiusY = radiusX * _perspectiveRatio;
      int capacity = _orbitCapacities[ringIndex];
      int internsOnThisRing = math.min(capacity, _filteredInterns.length - currentInternIndex);

      for (int i = 0; i < internsOnThisRing; i++) {
        double angle = (i / internsOnThisRing) * 2 * math.pi;
        if (ringIndex % 2 != 0) angle += (math.pi / internsOnThisRing); 
        double x = centerX + radiusX * math.cos(angle);
        double y = centerY + radiusY * math.sin(angle);

        planets.add(
          Positioned(
            // Apply scale factor to positioning offsets so cards stay centered on the orbit ring
            left: x - (80 * scaleFactor), 
            top: y - (160 * scaleFactor),
            child: OrbitalPlanetNode(
              intern: _filteredInterns[currentInternIndex], 
              ringIndex: ringIndex,
              isDark: isDark,
              scaleFactor: scaleFactor, // Pass scale to the node
            ),
          ),
        );
        currentInternIndex++;
      }
    }
    return planets;
  }
}

class OrbitRingsPainter extends CustomPainter {
  final List<double> radiiX;
  final double perspectiveRatio;
  final Color color;

  OrbitRingsPainter({required this.radiiX, required this.perspectiveRatio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double rx in radiiX) {
      double ry = rx * perspectiveRatio;
      Rect rect = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);
      canvas.drawOval(rect, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CentralSun extends StatelessWidget {
  final bool isDark;
  const CentralSun({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const Color fieryRed = Color(0xFFD50000);
    const Color coronaYellow = Color(0xFFFFD600);
    const Color ambientPurple = Color(0xFF6200EA);
    
    const Color sunYellow = Color(0xFFFFF176);
    const Color paleYellow = Color(0xFFFFF9C4);
    const Color coreWhite = Colors.white;

    return SizedBox(
      width: 500,
      height: 500,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isDark)
            Container(
              width: 490,
              height: 490,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ambientPurple.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          
          if (isDark)
            Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    fieryRed.withValues(alpha: 0.6),
                    fieryRed.withValues(alpha: 0.0),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),

          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: coronaYellow.withValues(alpha: isDark ? 0.9 : 0.8),
                  blurRadius: 40,
                  spreadRadius: isDark ? 2 : 12,
                ),
                BoxShadow(
                  color: coreWhite.withValues(alpha: 0.8),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),

          Container(
            width: 195,
            height: 195,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF02030A) : coreWhite,
              gradient: isDark ? null : const RadialGradient(
                colors: [coreWhite, paleYellow, sunYellow],
                stops: [0.3, 0.8, 1.0],
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(
                  color: sunYellow.withValues(alpha: 0.4),
                  blurRadius: 25,
                  spreadRadius: 5,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrbitalPlanetNode extends StatelessWidget {
  final InternProfile intern;
  final int ringIndex;
  final bool isDark;
  final double scaleFactor;

  const OrbitalPlanetNode({
    super.key, 
    required this.intern, 
    required this.ringIndex, 
    required this.isDark,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final List<Color> accents = [
      const Color(0xFF6366F1), 
      const Color(0xFF5A54FF), 
      const Color(0xFF42A5F5), 
      isDark ? Colors.white : const Color(0xFF00022E),
      const Color(0xFFAB47BC), 
    ];
    Color accentColor = accents[ringIndex % accents.length];

    // Ensure text doesn't become impossibly small to read
    final double titleFontSize = math.max(12 * scaleFactor, 8.0);
    final double subFontSize = math.max(9 * scaleFactor, 6.0);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => InternDetailPage(intern: intern)),
        );
      },
      child: SizedBox(
        // Apply scaling to the container size
        width: 160 * scaleFactor,
        height: 180 * scaleFactor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8 * scaleFactor),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 4 * scaleFactor, 
                    vertical: 6 * scaleFactor
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8 * scaleFactor),
                    border: Border(
                      bottom: BorderSide(color: accentColor.withValues(alpha: 0.8), width: 2 * scaleFactor),
                    ),
                    boxShadow: isDark ? [] : [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 4 * scaleFactor))
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        intern.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF00022E),
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2 * scaleFactor),
                      Text(
                        intern.internNumber,
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          fontSize: subFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12 * scaleFactor),
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow scales dynamically
                Container(
                  width: 54 * scaleFactor,
                  height: 54 * scaleFactor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: isDark ? 0.4 : 0.2),
                        blurRadius: 15 * scaleFactor,
                        spreadRadius: 2 * scaleFactor,
                      ),
                    ],
                  ),
                ),
                // Inner ring scales dynamically
                Container(
                  width: 50 * scaleFactor,
                  height: 50 * scaleFactor,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withValues(alpha: 0.8), width: 1.5 * scaleFactor),
                  ),
                  child: ClipOval(
                    child: Container(
                      color: isDark ? const Color(0xFF141526) : Colors.white,
                      child: InternAvatar(
                        intern: intern,
                        size: 50 * scaleFactor,
                        borderRadius: 25 * scaleFactor,
                        fontSize: 20 * scaleFactor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 20 * scaleFactor,
              width: 1 * scaleFactor,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentColor.withValues(alpha: 0.5), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PointerInterceptor extends StatelessWidget {
  final Widget child;
  const PointerInterceptor({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: child,
    );
  }
}