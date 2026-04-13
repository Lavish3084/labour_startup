import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_theme.dart';

class MainScreen extends StatefulWidget {
  final int? initialIndex;
  const MainScreen({super.key, this.initialIndex});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late ValueNotifier<double> _displayPage;
  late AnimationController _pillAnimationController;
  Animation<double>? _pillAnimation;
  bool _isDraggingNavbar = false;
  int _lastTab = 0;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    
    if (widget.initialIndex != null) {
      appState.setTab(widget.initialIndex!);
    }
    
    _lastTab = appState.selectedTab;
    _pageController = PageController(initialPage: _lastTab);
    _displayPage = ValueNotifier<double>(_lastTab.toDouble());

    _pillAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Sync displayPage with PageView during body swipes
    _pageController.addListener(() {
      if (!_isDraggingNavbar) {
        _displayPage.value = _pageController.page ?? _lastTab.toDouble();
      }
    });

    // Listen for external tab changes
    appState.addListener(_onAppStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appState.fetchProfile();
      appState.fetchBookings();
    });
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    if (appState.selectedTab != _lastTab) {
      _lastTab = appState.selectedTab;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _lastTab,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
        );
      }
    }
  }

  @override
  void dispose() {
    // Safely remove the listener
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.removeListener(_onAppStateChanged);
    _pageController.dispose();
    _displayPage.dispose();
    _pillAnimationController.dispose();
    super.dispose();
  }

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    BookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          if (!mounted) return;
          // IMPORTANT: Only update state if the user is physically swiping.
          // This prevents intermediate crossing signals during animateToPage(0 -> 2).
          if (_pageController.position.userScrollDirection !=
              ScrollDirection.idle) {
            final appState = Provider.of<AppStateProvider>(
              context,
              listen: false,
            );
            appState.setTab(index);
          }
        },
        children: _pages,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, navBarConstraints) {
          // Narrower bar width: 75% of screen width
          final double actualWidth = navBarConstraints.maxWidth * 0.75;
          final double sectionWidth = actualWidth / 3;

          return GestureDetector(
            onHorizontalDragStart: (_) {
              _isDraggingNavbar = true;
              _pillAnimationController.stop();
            },
            onHorizontalDragUpdate: (details) {
              if (_pageController.hasClients) {
                // Move pill independently within the navbar (Independent Grab & Slide)
                _displayPage.value = (_displayPage.value +
                        details.delta.dx / sectionWidth)
                    .clamp(0.0, 2.0);
              }
            },
            onHorizontalDragEnd: (details) {
              if (_pageController.hasClients) {
                final double startPage = _displayPage.value;
                final int targetPage = startPage.round().clamp(0, 2);

                // Create a smooth animation for the pill from its release point to the target
                _pillAnimation = Tween<double>(
                  begin: startPage,
                  end: targetPage.toDouble(),
                ).animate(
                  CurvedAnimation(
                    parent: _pillAnimationController,
                    curve: Curves.easeOutQuart,
                  ),
                );

                void updateDisplayPage() {
                  _displayPage.value = _pillAnimation!.value;
                }

                _pillAnimation!.addListener(updateDisplayPage);

                _pillAnimationController.forward(from: 0).then((_) {
                  if (mounted) {
                    _pillAnimation?.removeListener(updateDisplayPage);
                    _isDraggingNavbar = false;
                  }
                });

                // Simultaneously animate the PageView (the body)
                _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutQuart,
                );
              }
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 65,
                width: actualWidth,
                margin: const EdgeInsets.only(bottom: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 18,
                      sigmaY: 18,
                    ), // Increased blur for a deeper glass effect
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(
                              alpha: 0.06,
                            ), // Reduced frost for higher transparency
                            AppTheme.saffron.withValues(
                              alpha: 0.03,
                            ), // Subtle saffron tint kept clear
                          ],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ListenableBuilder(
                            listenable: _displayPage,
                            builder: (context, _) {
                              final double width = constraints.maxWidth;
                              final double sectionWidthInner = width / 3;
                              double page = _displayPage.value;

                              double fraction = page % 1.0;
                              if (page < 0) fraction = 0;
                              if (page > 2) fraction = 0;

                              double stretchFactor =
                                  (0.5 - (fraction - 0.5).abs()) * 2.0;
                              double stretchMagnitude =
                                  sectionWidthInner * 0.55;
                              double basePillWidth = sectionWidthInner * 0.43;
                              double currentWidth =
                                  basePillWidth +
                                  (stretchMagnitude * stretchFactor);

                              // Dynamic vertical bulge - Scaled for 65px height
                              double baseHeight = 44;
                              double currentHeight =
                                  baseHeight + (16 * stretchFactor);

                              double centerPos =
                                  (page + 0.5) * sectionWidthInner;
                              double leftPos = centerPos - (currentWidth / 2);

                              return Stack(
                                children: [
                                  // Liquid Stretchy Glass Selection Pill
                                  Positioned(
                                    left: leftPos,
                                    top:
                                        (constraints.maxHeight -
                                            currentHeight) /
                                        2,
                                    child: Container(
                                      width: currentWidth,
                                      height: currentHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                            AppTheme.saffron.withValues(
                                              alpha: 0.45,
                                            ),
                                            AppTheme.saffron.withValues(
                                              alpha: 0.15,
                                            ),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          stops: const [0.0, 0.4, 1.0],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          width: 0.8,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.saffron.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 15,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 4),
                                          ),
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 0,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Nav Items Row
                                  Row(
                                    children: [
                                      _buildNavItem(
                                        0,
                                        page,
                                        Icons.home_rounded,
                                        Icons.home_outlined,
                                        'Home',
                                      ),
                                      _buildNavItem(
                                        1,
                                        page,
                                        Icons.calendar_month_rounded,
                                        Icons.calendar_month_outlined,
                                        'Booking',
                                      ),
                                      _buildNavItem(
                                        2,
                                        page,
                                        Icons.person_rounded,
                                        Icons.person_outlined,
                                        'Profile',
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildNavItem(
    int index,
    double page,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    double pageDelta = (page - index).abs();
    double activeProgress = (1.0 - pageDelta).clamp(0.0, 1.0);
    bool isActive = activeProgress > 0.5;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _pageController.animateToPage(
            index,
            duration: const Duration(
              milliseconds: 630,
            ), // Slightly longer for a more premium ease-out
            curve: Curves.easeOutQuart,
          );

          final appState = Provider.of<AppStateProvider>(
            context,
            listen: false,
          );
          appState.setTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -2 * activeProgress),
              child: Transform.scale(
                scale: 1.0 + (0.15 * activeProgress),
                child: Icon(
                  isActive ? activeIcon : inactiveIcon,
                  color: Color.lerp(
                    AppTheme.textMuted.withValues(alpha: 0.6),
                    AppTheme.saffron,
                    activeProgress,
                  ),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Opacity(
              opacity: activeProgress,
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: AppTheme.saffron,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
