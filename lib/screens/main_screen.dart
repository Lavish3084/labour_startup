import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'home_screen.dart';
import 'bookings_screen.dart';
import 'profile_screen.dart';
import 'wallet_screen.dart';
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
  late AppStateProvider _appState;
  int _lastTab = 0;

  @override
  void initState() {
    super.initState();
    _appState = Provider.of<AppStateProvider>(context, listen: false);
    
    // Determine the starting tab safely
    _lastTab = widget.initialIndex ?? _appState.selectedTab;
    
    if (widget.initialIndex != null && widget.initialIndex != _appState.selectedTab) {
      // Sync the provider state after the current build phase to avoid the build-phase error
      Future.microtask(() => _appState.setTab(widget.initialIndex!));
    }
    
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
    _appState.addListener(_onAppStateChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appState.fetchProfile();
      _appState.fetchBookings();
    });
  }

  void _onAppStateChanged() {
    if (!mounted) return;
    if (_appState.selectedTab != _lastTab) {
      _lastTab = _appState.selectedTab;
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
    _appState.removeListener(_onAppStateChanged);
    _pageController.dispose();
    _displayPage.dispose();
    _pillAnimationController.dispose();
    super.dispose();
  }

  static const List<Widget> _pages = <Widget>[
    HomeScreen(),
    BookingsScreen(),
    WalletScreen(),
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
            _appState.setTab(index);
          }
        },
        children: _pages,
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, navBarConstraints) {
          // Slightly wider for 4 items: 90% of screen width
          // Figma reference: 88% width (left: 24 on 402px)
          final double actualWidth = navBarConstraints.maxWidth * 0.88;
          final double sectionWidth = actualWidth / 4;

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
                    .clamp(0.0, 3.0);
              }
            },
            onHorizontalDragEnd: (details) {
              if (_pageController.hasClients) {
                final double startPage = _displayPage.value;
                final int targetPage = startPage.round().clamp(0, 3);

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
                height: 75,
                width: actualWidth,
                margin: const EdgeInsets.only(bottom: 30),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 18,
                      sigmaY: 18,
                    ), // Increased blur for a deeper glass effect
                    child: Container(
                        decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return ListenableBuilder(
                            listenable: _displayPage,
                            builder: (context, _) {
                              final double width = constraints.maxWidth;
                              // Uniform padding for perfect symmetry
                              const double horizontalPadding = 24;
                              final double sectionWidthInner = (width - (horizontalPadding * 2)) / 4;
                              double page = _displayPage.value;

                              // Advanced stretching pill logic
                              double fraction = (page % 1.0).abs();
                              // Correctly handle the edges
                              if (page < 0) fraction = 0;
                              if (page > 3) fraction = 0;

                              double stretchFactor = (0.5 - (fraction - 0.5).abs()) * 2.0;
                              double basePillWidth = 14;
                              // The pill stretches significantly when moving between tabs
                              double stretchMax = sectionWidthInner * 0.7;
                              double currentWidth = basePillWidth + (stretchMax * stretchFactor);

                              // Calculate center position relative to the row items
                              double centerX = horizontalPadding + (page + 0.5) * sectionWidthInner;
                              double leftPos = centerX - (currentWidth / 2);

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
                                child: Row(
                                  children: [
                                    _buildNavItem(0, page, Icons.home_rounded, Icons.home_outlined, 'Home'),
                                    _buildNavItem(1, page, Icons.assignment_rounded, Icons.assignment_outlined, 'Bookings'),
                                    _buildNavItem(2, page, Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Wallet'),
                                    _buildNavItem(3, page, Icons.person_rounded, Icons.person_outlined, 'Profile'),
                                  ],
                                ),
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
            ),
            curve: Curves.easeOutQuart,
          );

          _appState.setTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + (0.1 * activeProgress),
                child: Icon(
                  activeIcon, // Always filled icons
                  color: isActive ? AppTheme.brandGreenMain : AppTheme.textMuted.withValues(alpha: 0.5),
                  size: 33, // Slightly larger
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF4A9782) : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
