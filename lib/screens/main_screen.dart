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
import '../widgets/floating_cart_banner.dart';

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

    if (widget.initialIndex != null &&
        widget.initialIndex != _appState.selectedTab) {
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

  static const List<Widget> _pages = <Widget>[HomeScreen(), BookingsScreen()];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            PageView(
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
            ValueListenableBuilder<double>(
              valueListenable: _displayPage,
              builder: (context, page, _) {
                if (page < 0.5) {
                  return Positioned(
                    bottom: 90,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: (1.0 - (page * 2)).clamp(0.0, 1.0),
                      child: const FloatingCartBanner(bottomInset: 0),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        bottomNavigationBar: LayoutBuilder(
          builder: (context, navBarConstraints) {
            final double screenWidth = navBarConstraints.maxWidth;
            final double sectionWidth = screenWidth / 3;

            return GestureDetector(
              onHorizontalDragStart: (_) {
                _isDraggingNavbar = true;
                _pillAnimationController.stop();
              },
              onHorizontalDragUpdate: (details) {
                if (_pageController.hasClients) {
                  _displayPage.value = (_displayPage.value +
                          details.delta.dx / sectionWidth)
                      .clamp(0.0, 1.0);
                }
              },
              onHorizontalDragEnd: (details) {
                if (_pageController.hasClients) {
                  final double startPage = _displayPage.value;
                  final int targetPage = startPage.round().clamp(0, 1);

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
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: SafeArea(
                        top: false,
                        child: Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListenableBuilder(
                            listenable: _displayPage,
                            builder: (context, _) {
                              double page = _displayPage.value;

                              return Row(
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
                                    Icons.assignment_rounded,
                                    Icons.assignment_outlined,
                                    'Bookings',
                                  ),
                                  _buildWalletButton(),
                                ],
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
            duration: const Duration(milliseconds: 630),
            curve: Curves.easeOutQuart,
          );

          _appState.setTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isActive
                      ? AppTheme.brandGreenMain.withOpacity(
                        0.12,
                      ) // Soft mint green highlight
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  isActive
                      ? activeIcon
                      : inactiveIcon, // Swap outline/filled icons dynamically
                  color:
                      isActive
                          ? AppTheme.brandGreenMain
                          : AppTheme.textMuted.withOpacity(0.7),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color:
                        isActive ? AppTheme.brandGreenMain : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletButton() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WalletScreen()),
          );
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Will',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'MONEY',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.2,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
