import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/service_category.dart';
import '../services/api_service.dart';
import 'searching_worker_screen.dart';
import 'booking_accepted_screen.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/concave_header_clipper.dart';
import '../widgets/pattern_painter.dart';

const String gpaySvg = '''
<svg height="800px" width="800px" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" 
	 viewBox="0 0 2387.3 948" xml:space="preserve">
<style type="text/css">
	.st0{fill:#5F6368;}
	.st1{fill:#4285F4;}
	.st2{fill:#34A853;}
	.st3{fill:#FBBC04;}
	.st4{fill:#EA4335;}
</style>
<g>
	<path class="st0" d="M1129.1,463.2V741h-88.2V54.8h233.8c56.4-1.2,110.9,20.2,151.4,59.4c41,36.9,64.1,89.7,63.2,144.8
		c1.2,55.5-21.9,108.7-63.2,145.7c-40.9,39-91.4,58.5-151.4,58.4L1129.1,463.2L1129.1,463.2z M1129.1,139.3v239.6h147.8
		c32.8,1,64.4-11.9,87.2-35.5c46.3-45,47.4-119.1,2.3-165.4c-0.8-0.8-1.5-1.6-2.3-2.3c-22.5-24.1-54.3-37.3-87.2-36.4L1129.1,139.3
		L1129.1,139.3z M1692.5,256.2c65.2,0,116.6,17.4,154.3,52.2c37.7,34.8,56.5,82.6,56.5,143.2V741H1819v-65.2h-3.8
		c-36.5,53.7-85.1,80.5-145.7,80.5c-51.7,0-95-15.3-129.8-46c-33.8-28.5-53-70.7-52.2-115c0-48.6,18.4-87.2,55.1-115.9
		c36.7-28.7,85.7-43.1,147.1-43.1c52.3,0,95.5,9.6,129.3,28.7v-20.2c0.2-30.2-13.2-58.8-36.4-78c-23.3-21-53.7-32.5-85.1-32.1
		c-49.2,0-88.2,20.8-116.9,62.3l-77.6-48.9C1545.6,286.8,1608.8,256.2,1692.5,256.2L1692.5,256.2z M1578.4,597.3
		c-0.1,22.8,10.8,44.2,29.2,57.5c19.5,15.3,43.7,23.5,68.5,23c37.2-0.1,72.9-14.9,99.2-41.2c29.2-27.5,43.8-59.7,43.8-96.8
		c-27.5-21.9-65.8-32.9-115-32.9c-35.8,0-65.7,8.6-89.6,25.9C1590.4,550.4,1578.4,571.7,1578.4,597.3L1578.4,597.3z M2387.3,271.5
		L2093,948h-91l109.2-236.7l-193.6-439.8h95.8l139.9,337.3h1.9l136.1-337.3L2387.3,271.5z"/>
</g>
<path class="st1" d="M772.8,403.2c0-26.9-2.2-53.7-6.8-80.2H394.2v151.8h212.9c-8.8,49-37.2,92.3-78.7,119.8v98.6h127.1
	C729.9,624.7,772.8,523.2,772.8,403.2L772.8,403.2z"/>
<path class="st2" d="M394.2,788.5c106.4,0,196-34.9,261.3-95.2l-127.1-98.6c-35.4,24-80.9,37.7-134.2,37.7
	c-102.8,0-190.1-69.3-221.3-162.7H42v101.6C108.9,704.5,245.2,788.5,394.2,788.5z"/>
<path class="st3" d="M172.9,469.7c-16.5-48.9-16.5-102,0-150.9V217.2H42c-56,111.4-56,242.7,0,354.1L172.9,469.7z"/>
<path class="st4" d="M394.2,156.1c56.2-0.9,110.5,20.3,151.2,59.1L658,102.7C586.6,35.7,492.1-1.1,394.2,0
	C245.2,0,108.9,84.1,42,217.2l130.9,101.6C204.1,225.4,291.4,156.1,394.2,156.1z"/>
</svg>''';

const String paytmSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36" fill="none">
  <g clip-path="url(#clip0_114_618)">
    <path d="M23.775 12.2505L23.715 12.2565C22.695 12.5415 22.9005 13.9785 21.0435 14.1015H20.8635C20.8373 14.1006 20.8111 14.1031 20.7855 14.109H20.784C20.705 14.128 20.6347 14.1731 20.5846 14.2372C20.5344 14.3012 20.5075 14.3802 20.508 14.4615V16.0965C20.508 16.2975 20.667 16.458 20.8635 16.458H21.831V23.3925C21.831 23.5905 21.987 23.7495 22.1805 23.7495H23.7675C23.8611 23.7483 23.9505 23.7101 24.016 23.6432C24.0815 23.5763 24.1178 23.4862 24.117 23.3925V16.458H25.017C25.212 16.458 25.371 16.2975 25.371 16.0965V14.4615C25.371 14.3671 25.3339 14.2764 25.2677 14.2091C25.2015 14.1417 25.1114 14.1031 25.017 14.1015H24.099V12.579C24.099 12.4925 24.0651 12.4095 24.0045 12.3478C23.9439 12.2861 23.8615 12.2521 23.775 12.2505ZM30.1125 14.0055C29.5155 14.0055 28.9695 14.2305 28.5495 14.598V14.412C28.5435 14.3223 28.5042 14.2381 28.4392 14.1759C28.3743 14.1137 28.2884 14.0781 28.1985 14.076H26.5935C26.4986 14.0776 26.4081 14.1166 26.3418 14.1846C26.2755 14.2526 26.2387 14.3441 26.2395 14.439V23.319C26.2387 23.414 26.2755 23.5054 26.3418 23.5734C26.4081 23.6414 26.4986 23.6804 26.5935 23.682H28.1985C28.3785 23.682 28.524 23.5455 28.548 23.3685V16.9935C28.5419 16.8389 28.5968 16.688 28.7009 16.5735C28.805 16.459 28.95 16.3901 29.1045 16.3815H29.3985C29.5228 16.3902 29.6413 16.4374 29.7375 16.5165C29.8077 16.5745 29.8638 16.6478 29.9014 16.7307C29.9391 16.8136 29.9574 16.904 29.955 16.995V23.106L29.961 23.3385C29.9606 23.4335 29.9977 23.5248 30.0643 23.5925C30.1309 23.6602 30.2216 23.6988 30.3165 23.7H31.9215C32.0131 23.6982 32.1006 23.6615 32.1661 23.5974C32.2316 23.5333 32.2702 23.4466 32.274 23.355L32.2725 16.986C32.2725 16.776 32.3655 16.587 32.5335 16.476C32.6208 16.4168 32.7222 16.3816 32.8275 16.374H33.1245C33.4695 16.404 33.6795 16.674 33.6795 16.986C33.687 19.08 33.6855 21.186 33.6855 23.322C33.6851 23.417 33.7222 23.5083 33.7888 23.576C33.8554 23.6437 33.9461 23.6823 34.041 23.6835H35.646C35.841 23.6835 36 23.5215 36 23.322V16.5075C36 16.0425 35.949 15.8445 35.88 15.642C35.7203 15.1672 35.4161 14.7542 35.0099 14.461C34.6037 14.1678 34.116 14.0091 33.615 14.007H33.5925C33.2685 14.0073 32.948 14.074 32.6508 14.203C32.3536 14.332 32.086 14.5205 31.8645 14.757C31.428 14.295 30.8145 14.007 30.135 14.007L30.1125 14.0055ZM0.348013 14.1C0.301918 14.1004 0.256353 14.1099 0.213917 14.1279C0.171482 14.1459 0.133008 14.1721 0.100693 14.2049C0.0683782 14.2378 0.0428545 14.2767 0.0255797 14.3195C0.0083049 14.3622 -0.000382723 14.4079 1.29307e-05 14.454V23.34C1.29307e-05 23.538 0.144013 23.697 0.324013 23.7015H1.95901C2.15401 23.7015 2.31451 23.541 2.31451 23.3415L2.32051 20.8545H3.85501C5.14051 20.8545 6.03451 19.947 6.03451 18.633V16.326C6.03451 15.0105 5.14051 14.1 3.85501 14.1H0.348013ZM13.896 14.1C13.8011 14.1012 13.7104 14.1399 13.6438 14.2076C13.5772 14.2753 13.5401 14.3666 13.5405 14.4615V18.1665C13.5405 19.5765 14.526 20.5785 15.909 20.5785H16.9215C16.9215 20.5785 16.9455 20.5785 16.977 20.5845C17.0694 20.5959 17.1544 20.6409 17.2158 20.7109C17.2772 20.7808 17.3107 20.8709 17.31 20.964C17.31 21.159 17.166 21.3165 16.9815 21.3405L16.9545 21.3465L16.5 21.3555H14.6085C14.5141 21.3571 14.424 21.3957 14.3578 21.4631C14.2916 21.5304 14.2545 21.6211 14.2545 21.7155V23.3505C14.2537 23.4455 14.2905 23.5369 14.3568 23.6049C14.4231 23.6729 14.5136 23.7119 14.6085 23.7135H17.2335C18.6135 23.7135 19.599 22.71 19.599 21.3015V14.4615C19.599 14.3671 19.5619 14.2764 19.4957 14.2091C19.4295 14.1417 19.3394 14.1031 19.245 14.1015H17.64C17.5456 14.1031 17.4555 14.1417 17.3893 14.2091C17.3231 14.2764 17.286 14.3671 17.286 14.4615C17.2785 15.642 17.286 16.749 17.286 17.844C17.2848 17.9431 17.245 18.0378 17.1749 18.1079C17.1048 18.178 17.0101 18.2179 16.911 18.219H16.2375C16.1371 18.2178 16.0413 18.1769 15.971 18.1052C15.9007 18.0335 15.8617 17.9369 15.8625 17.8365C15.87 16.7055 15.855 15.5865 15.855 14.4615C15.855 14.3671 15.8179 14.2764 15.7517 14.2091C15.6855 14.1417 15.5954 14.1031 15.501 14.1015L13.896 14.1ZM7.89001 14.109C7.84421 14.1074 7.79854 14.115 7.75569 14.1312C7.71283 14.1475 7.67364 14.1721 7.6404 14.2036C7.60717 14.2352 7.58055 14.2731 7.56211 14.315C7.54367 14.357 7.53378 14.4022 7.53301 14.448V15.9825C7.53301 16.1805 7.70251 16.3425 7.91101 16.3425H10.0305C10.1985 16.368 10.3305 16.4925 10.35 16.6875V16.8975C10.3305 17.0835 10.2 17.2185 10.0395 17.2335H8.98951C7.59451 17.2335 6.59851 18.1785 6.59851 19.506V21.4095C6.59851 22.7295 7.45351 23.6685 8.84101 23.6685H11.751C12.273 23.6685 12.696 23.2635 12.696 22.7685V16.5645C12.696 15.0585 11.934 14.109 10.116 14.109H7.89001ZM2.32051 16.467H3.33751C3.54601 16.467 3.71251 16.6395 3.71251 16.851V18.105C3.71311 18.1549 3.70388 18.2043 3.68535 18.2506C3.66683 18.2969 3.63937 18.339 3.60455 18.3747C3.56973 18.4104 3.52822 18.4388 3.4824 18.4584C3.43658 18.478 3.38735 18.4884 3.33751 18.489H3.18751C2.89851 18.491 2.60951 18.491 2.32051 18.489V16.467ZM9.32551 19.4325H9.99301C10.2015 19.4325 10.371 19.5945 10.371 19.7925V21.1905C10.3715 21.2295 10.3644 21.2682 10.35 21.3045C10.3233 21.3774 10.2746 21.4403 10.2107 21.4843C10.1467 21.5284 10.0707 21.5515 9.99301 21.5505H9.32551C9.22775 21.5525 9.13316 21.5158 9.06235 21.4484C8.99154 21.381 8.95026 21.2883 8.94751 21.1905V19.791C8.94751 19.593 9.11701 19.4325 9.32551 19.4325Z" fill="#41C0FF"/>
  </g>
  <defs>
    <clipPath id="clip0_114_618">
      <rect width="36" height="36" fill="white"/>
    </clipPath>
  </defs>
</svg>''';

class BookingSetupScreen extends StatefulWidget {
  final ServiceCategory category;
  final String bookingMode;
  final DateTime scheduledTime;
  final int? numberOfHours;
  final String address;
  final double latitude;
  final double longitude;
  final double amount;
  final int numberOfWorkers;
  final String workType;
  final List<String>? taskImagesBase64;
  final String? taskAudioBase64;
  final String? taskNotes;

  const BookingSetupScreen({
    super.key,
    required this.category,
    required this.bookingMode,
    required this.scheduledTime,
    this.numberOfHours,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.amount,
    this.numberOfWorkers = 1,
    this.workType = '',
    this.taskImagesBase64,
    this.taskAudioBase64,
    this.taskNotes,
  });

  @override
  State<BookingSetupScreen> createState() => _BookingSetupScreenState();
}

class _BookingSetupScreenState extends State<BookingSetupScreen> {
  bool _isLoading = false;
  int _selectedTip = 0;
  late PaymentService _paymentService;
  String? _currentBookingId;
  int? _serverFee;
  bool _useWallet = false;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(context, listen: false).fetchWalletBalance();
    });
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_currentBookingId == null) return;

    setState(() => _isLoading = true);
    try {
      final success = await ApiService.verifyPayment(
        response.orderId!,
        response.paymentId!,
        response.signature!,
        _currentBookingId!,
      );

      if (success) {
        if (!mounted) return;
        _navigateToNextScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed. Please contact support.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet Selected: ${response.walletName}')),
    );
  }

  void _navigateToNextScreen() {
    final hoursDifference = widget.scheduledTime.difference(DateTime.now()).inHours;
    
    if (hoursDifference <= 12) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SearchingWorkerScreen(
            category: widget.category,
            address: widget.address,
            scheduledTime: widget.scheduledTime,
            latitude: widget.latitude,
            longitude: widget.longitude,
            bookingData: {'_id': _currentBookingId}, 
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingAcceptedScreen(
            category: widget.category,
            address: widget.address,
            scheduledTime: widget.scheduledTime,
            bookingData: {'_id': _currentBookingId}, 
          ),
        ),
      );
    }
  }
  
  double get _bookingFee => (widget.category.commissionPercentage / 100) * widget.amount;
  
  int get _finalFeeAmount => _serverFee ?? _bookingFee.ceil();
  
  Future<void> _handleBookNow() async {
    setState(() => _isLoading = true);

    try {
      final finalAmount = widget.amount + _selectedTip;
      
      // 1. Create the booking FIRST (Pending Payment, not broadcasted yet)
      final result = await ApiService.createBooking(
        category: widget.category.name,
        date: widget.scheduledTime,
        bookingMode: widget.bookingMode,
        numberOfHours: widget.numberOfHours,
        notes: widget.taskNotes,
        problemTitle: widget.category.name,
        taskImages: widget.taskImagesBase64,
        taskAudio: widget.taskAudioBase64,
        address: widget.address,
        latitude: widget.latitude,
        longitude: widget.longitude,
        amount: finalAmount,
        numberOfWorkers: widget.numberOfWorkers,
        workType: widget.workType,
      );

      if (result['success']) {
        final bookingData = result['data'];
        _currentBookingId = bookingData['_id'];
        
        // Capture the official fee from the server
        if (bookingData['commissionAmount'] != null) {
          _serverFee = (bookingData['commissionAmount'] as num).toInt();
        }
        
        if (_finalFeeAmount <= 0) {
          // Skip payment gateway for 0-fee bookings
          final success = await ApiService.confirmFreeBooking(_currentBookingId!);
          if (success) {
            _navigateToNextScreen();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to confirm booking. Please try again.')),
            );
          }
        } else if (_useWallet) {
          // 2. Pay using Wallet
          final success = await ApiService.payWithWallet(_currentBookingId!);
          if (success) {
            _navigateToNextScreen();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to pay with wallet. Please try again.')),
            );
          }
        } else {
          // 2. Create Razorpay Order for the platform fee
          final int feeInPaise = _finalFeeAmount * 100;
          final orderData = await ApiService.createPaymentOrder(_currentBookingId!, feeInPaise);
          
          // 3. Open Razorpay Checkout
          final String razorpayKeyId = dotenv.get('RAZORPAY_KEY_ID', fallback: '');
          
          _paymentService.openCheckout(
            keyId: razorpayKeyId,
            orderId: orderData['id'],
            name: 'Labour App',
            description: '${widget.category.name} Booking Fee',
            email: '', 
            contact: '', 
            amount: feeInPaise,
          );
        }
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to create booking')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const double _headerHeight = 272;
  /// White sheet starts below the header title (no overlap on load).
  static const double _sheetOverlapTop = 224;

  @override
  Widget build(BuildContext context) {
    final bottomBarPadding =
        120.0 + MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF2E876E),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _headerHeight,
                child: _buildHeader(),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(
                        height: _sheetOverlapTop,
                        child: const IgnorePointer(),
                      ),
                      _buildOverlappingSheet(
                        bottomPadding: bottomBarPadding,
                        minHeight: viewportHeight - _sheetOverlapTop,
                      ),
                    ],
                  ),
                ),
              ),
              _buildHeaderBackButton(),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomBar(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverlappingSheet({
    required double bottomPadding,
    required double minHeight,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
            child: _buildBookingDetailsCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSection() {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final walletBalance = appState.walletBalance;
        final hasEnoughBalance = walletBalance >= _finalFeeAmount;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F9F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Color(0xFF2E876E)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pay with Wallet',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Balance: ₹${walletBalance.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 14, 
                        color: hasEnoughBalance ? const Color(0xFF4A9782) : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _useWallet,
                onChanged: hasEnoughBalance ? (val) {
                  setState(() {
                    _useWallet = val;
                  });
                } : null,
                activeColor: const Color(0xFF2E876E),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      child: Material(
        color: Colors.transparent,
        child: CircleAvatar(
          backgroundColor: Colors.white,
          radius: 20,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2E876E), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: const ConcaveBottomHeaderClipper(radius: 40),
      child: Container(
        width: double.infinity,
        height: _headerHeight,
        color: const Color(0xFF2E876E),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: DotPatternPainter(),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, color: Color(0xFF2E876E), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '100% Refundable*',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF2E876E),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _finalFeeAmount <= 0
                        ? 'Confirm Your\n${widget.category.name} Booking'
                        : 'Secure Your\nBooking For ₹$_finalFeeAmount',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDetailsSection(),
        _buildTipSection(),
        _buildPaymentSummarySection(),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Change',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E876E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          _buildDetailsRow(Icons.engineering_outlined, 'Service', widget.workType.isNotEmpty ? widget.workType : widget.category.name),
          const SizedBox(height: 12),
          _buildDetailsRow(Icons.calendar_today_outlined, 'Date & Time', '${DateFormat('dd MMMM yyyy').format(widget.scheduledTime)} • ${DateFormat('hh:mm a').format(widget.scheduledTime)}'),
          const SizedBox(height: 12),
          _buildDetailsRow(Icons.people_outline_rounded, 'Workers Required', '${widget.numberOfWorkers.toString().padLeft(2, '0')} Worker${widget.numberOfWorkers > 1 ? "s" : ""}'),
          const SizedBox(height: 12),
          _buildDetailsRow(Icons.access_time_rounded, 'Duration', widget.bookingMode == 'Hourly' ? '${widget.numberOfHours} Hours' : 'Daily'),
          const SizedBox(height: 12),
          _buildDetailsRow(Icons.location_on_outlined, 'Work Location', widget.address, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildDetailsRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1FAF7),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF2E876E)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: maxLines,
                overflow: maxLines == 1 ? TextOverflow.ellipsis : null,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: maxLines > 1 ? 1.3 : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTipSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Support Your Worker',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '100% to worker',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E876E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Add a tip to show appreciation for their hard work and support.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTipChip(50),
              const SizedBox(width: 8),
              _buildTipChip(100),
              const SizedBox(width: 8),
              _buildCustomTipChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummarySection() {
    final workerAmount = widget.amount.toInt();
    final bookingFee = _finalFeeAmount;
    final totalPayable = workerAmount + bookingFee + _selectedTip;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          _buildSummaryItem('Booking Fee (Pay Now)', '₹$bookingFee', isHighlight: true),
          const SizedBox(height: 12),
          _buildSummaryItem('Service Charges (Pay Worker Later)', '₹$workerAmount'),
          if (_selectedTip > 0) ...[
            const SizedBox(height: 12),
            _buildSummaryItem('Worker Tip (Pay Worker Later)', '₹$_selectedTip'),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Booking Value',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Incl. taxes and platform charges',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Text(
                '₹$totalPayable',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF2E876E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
            color: isHighlight ? const Color(0xFF2E876E) : Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isHighlight ? const Color(0xFF2E876E) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTipChip(int amount) {
    final isSelected = _selectedTip == amount;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTip = 0; // Toggle off
          } else {
            _selectedTip = amount;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD8F2E9) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: const Color(0xFF4A9782), width: 1) : null,
        ),
        child: Text(
          '+ $amount',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF2E876E) : const Color(0xFF4A9782),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTipChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        'Custom',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4A9782),
        ),
      ),
    );
  }

  void _showPaymentSelectionSheet() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final walletBalance = appState.walletBalance;
    final hasEnoughBalance = walletBalance >= _finalFeeAmount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Payment Method',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.black54),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you would like to secure your booking fee of ₹$_finalFeeAmount',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              // Pay with Wallet Option
              InkWell(
                onTap: !hasEnoughBalance
                    ? null
                    : () {
                        Navigator.pop(context);
                        setState(() {
                          _useWallet = true;
                        });
                        _handleBookNow();
                      },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: hasEnoughBalance ? const Color(0xFFE5E7EB) : Colors.grey[200]!,
                    ),
                    color: hasEnoughBalance ? Colors.white : const Color(0xFFF9FAFB),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: hasEnoughBalance
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: hasEnoughBalance
                              ? const Color(0xFF2E876E)
                              : Colors.grey[400],
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pay with Wallet',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: hasEnoughBalance ? Colors.black87 : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasEnoughBalance
                                  ? 'Balance: ₹${walletBalance.toStringAsFixed(2)}'
                                  : 'Insufficient Balance: ₹${walletBalance.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: hasEnoughBalance
                                    ? const Color(0xFF4A9782)
                                    : Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: hasEnoughBalance ? Colors.black54 : Colors.grey[300],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Razorpay / Continue to Pay Option
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _useWallet = false;
                  });
                  _handleBookNow();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF4EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payment_rounded,
                          color: Color(0xFFFF6B00),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Continue to Pay',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UPI, Cards, NetBanking, etc. via Razorpay',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /*
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Payment\nOption :',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              Row(
                children: [
                  SvgPicture.string(gpaySvg, width: 41, height: 17, fit: BoxFit.contain),
                  const SizedBox(width: 12),
                  SvgPicture.string(paytmSvg, width: 36, height: 36),
                  const SizedBox(width: 12),
                  _buildMockWalletIcon(),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_drop_down, color: Colors.black54),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          */
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Fee', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text('₹$_finalFeeAmount', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF4A9782))),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_finalFeeAmount <= 0) {
                              _handleBookNow();
                            } else {
                              _showPaymentSelectionSheet();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9782),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Confirm Booking',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
