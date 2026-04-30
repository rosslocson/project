import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import 'intern_widgets.dart';

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
  
  // Search Controls
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  // Map Controls
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animController;
  late Animation<Matrix4> _mapAnimation;

  // Defines the 3D perspective squish (0.4 means Y axis is 40% of X axis)
  final double _perspectiveRatio = 0.35; 
  double _canvasWidth = 3000.0;
  double _canvasHeight = 2000.0;

  // Orbit definitions (Semi-major axes / X-Radius)
  final List<double> _orbitRadiiX = [300.0, 550.0, 850.0, 1200.0, 1600.0];
  final List<int> _orbitCapacities = [6, 12, 24, 36, 50]; // How many fit on each ring

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
        // 1. Sort Alphabetically A-Z
        loaded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        _interns = loaded;
        _filteredInterns = loaded;
        
        // 2. Adjust canvas size if there are tons of users
        if (_interns.length > 128) {
          _orbitRadiiX.add(2000.0);
          _orbitCapacities.add(80);
          _canvasWidth = 4500.0;
          _canvasHeight = 3000.0;
        }
        
        _loading = false;
      });
      
      // Center the camera on the glowing star
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
        _filteredInterns = _interns.where((intern) =>
          intern.name.toLowerCase().contains(query) ||
          intern.internNumber.toLowerCase().contains(query)
        ).toList();
      }
    });
  }

  List<Widget> _buildUIChildren(BuildContext context) {
    List<Widget> children = [];
    
    // Top Header Layer (Wrapped in PointerInterceptor so interactions don't drag the map)
    children.add(
      PointerInterceptor(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // CENTER: Title (using Stack to keep it perfectly centered regardless of side buttons)
              const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SYSTEM DIRECTORY',
                    style: TextStyle(
                      color: Color(0xFF8A84FF), // Purple accent
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4.0,
                    ),
                  ),
                  Text(
                    'Orbital View',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              
              // EDGES: Back Button and Dynamic Search Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/dashboard');
                      }
                    },
                  ),
                  
                  // Expandable Inline Search Bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: _isSearching ? 280 : 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isSearching ? const Color(0xFF141526).withOpacity(0.9) : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isSearching ? const Color(0xFF8A84FF) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _isSearching
                              ? Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: 'Search name or number...',
                                      hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        IconButton(
                          icon: Icon(
                            _isSearching ? Icons.close : Icons.search,
                            color: Colors.white,
                          ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (_loading) {
      children.add(const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF8A84FF)))));
    }
    if (_error != null) {
      children.add(Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))));
    }
    
    children.add(const Spacer());
    
    if (!_loading && _error == null) {
      children.add(
        PointerInterceptor(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF141526).withOpacity(0.9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(color: Color(0xFF8A84FF), width: 1),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: _recenterMap,
              icon: const Icon(Icons.adjust, size: 18, color: Color(0xFF8A84FF)),
              label: const Text('Focus Core', style: TextStyle(letterSpacing: 1.0)),
            ),
          ),
        ),
      );
    }
    return children;
  }

  void _recenterMap({bool animated = true}) {
    final Size screenSize = MediaQuery.of(context).size;
    // Scale so the first few orbits fit perfectly on screen
    double targetScale = screenSize.width > 800 ? 0.7 : 0.4; 
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A), // Extremely deep space blue/black
      body: Stack(
        children: [
          // Ambient Space Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF0A0C1B), Color(0xFF02030A)],
              ),
            ),
          ),

          // The Interactive Solar System
          if (!_loading && _error == null)
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.1, 
              maxScale: 1.5,
              boundaryMargin: EdgeInsets.zero, // Prevents getting lost in empty space
              constrained: false,
              child: SizedBox(
                width: _canvasWidth,
                height: _canvasHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // 1. Draw the Elliptical Orbits
                    CustomPaint(
                      size: Size(_canvasWidth, _canvasHeight),
                      painter: OrbitRingsPainter(
                        radiiX: _orbitRadiiX,
                        perspectiveRatio: _perspectiveRatio,
                      ),
                    ),

                    // 2. The Central Glowing Star (Blue theme)
                    Positioned(
                      left: _canvasWidth / 2 - 250,
                      top: _canvasHeight / 2 - 250,
                      child: const CentralBlueStar(),
                    ),

                    // 3. The Planets (Interns)
                    ..._buildPlanetarySystem(),
                  ],
                ),
              ),
            ),

          // UI Overlay
          SafeArea(
            child: Column(
              children: _buildUIChildren(context),
            ),
          ),
        ],
      ),
    );
  }

  // Distributes interns onto the elliptical orbits
  List<Widget> _buildPlanetarySystem() {
    List<Widget> planets = [];
    final double centerX = _canvasWidth / 2;
    final double centerY = _canvasHeight / 2;
    
    int currentInternIndex = 0;

    for (int ringIndex = 0; ringIndex < _orbitRadiiX.length; ringIndex++) {
      if (currentInternIndex >= _filteredInterns.length) break;

      double radiusX = _orbitRadiiX[ringIndex];
      double radiusY = radiusX * _perspectiveRatio; // Squish Y to create the 3D angle
      
      int capacity = _orbitCapacities[ringIndex];
      int internsOnThisRing = math.min(capacity, _filteredInterns.length - currentInternIndex);

      for (int i = 0; i < internsOnThisRing; i++) {
        // Evenly space them along the ellipse
        double angle = (i / internsOnThisRing) * 2 * math.pi;
        
        // Offset alternating rings slightly for an organic look
        if (ringIndex % 2 != 0) {
          angle += (math.pi / internsOnThisRing); 
        }

        // Elliptical math for positioning
        double x = centerX + radiusX * math.cos(angle);
        double y = centerY + radiusY * math.sin(angle);

        planets.add(
          Positioned(
            left: x - 60, // Center the widget (assuming width is 120)
            top: y - 140, // Offset Y more so the avatar "stands up" on the line
            child: OrbitalPlanetNode(
              intern: _filteredInterns[currentInternIndex], 
              ringIndex: ringIndex,
            ),
          ),
        );
        
        currentInternIndex++;
      }
    }
    return planets;
  }
}

// ---------------------------------------------------------
// CUSTOM PAINTER: Draws the angled elliptical orbit lines
// ---------------------------------------------------------
class OrbitRingsPainter extends CustomPainter {
  final List<double> radiiX;
  final double perspectiveRatio;

  OrbitRingsPainter({required this.radiiX, required this.perspectiveRatio});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
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

// ---------------------------------------------------------
// THE CENTRAL GLOWING STAR (Blue-Purple Gradient Theme)
// ---------------------------------------------------------
class CentralBlueStar extends StatelessWidget {
  const CentralBlueStar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 500,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ambient glow
          Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF8A84FF).withOpacity(0.15), // Purple
                  const Color(0xFF5A54FF).withOpacity(0.05), // Deep Purple
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Inner intense corona
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8A84FF).withOpacity(0.6), // Purple
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// THE PLANET WIDGET (Intern Avatar)
// ---------------------------------------------------------
class OrbitalPlanetNode extends StatelessWidget {
  final InternProfile intern;
  final int ringIndex;

  const OrbitalPlanetNode({super.key, required this.intern, required this.ringIndex});

  @override
  Widget build(BuildContext context) {
    // Alternate accent colors based on their ring to give depth
    final List<Color> accents = [
      const Color(0xFF8A84FF), // Purple
      const Color(0xFF5A54FF), // Deep Purple
      const Color(0xFF42A5F5), // Blue
      const Color(0xFFFFFFFF), // White
      const Color(0xFFAB47BC), // Purple variant
    ];
    Color accentColor = accents[ringIndex % accents.length];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InternDetailPage(intern: intern),
          ),
        );
      },
      child: SizedBox(
        width: 120,
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // The Holographic Info Box
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      bottom: BorderSide(color: accentColor.withOpacity(0.8), width: 2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        intern.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        intern.internNumber,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // The Physical Planet (Avatar)
            Stack(
              alignment: Alignment.center,
              children: [
                // Planet Shadow/Glow
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                // The actual avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor.withOpacity(0.8), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Container(
                      color: const Color(0xFF141526),
                      child: InternAvatar(
                        intern: intern,
                        size: 50,
                        borderRadius: 25,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // A small dot connecting the avatar to the physical orbit line
            Container(
              height: 20,
              width: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accentColor.withOpacity(0.5), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Intercepts touches for the UI overlay buttons
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