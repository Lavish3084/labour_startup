import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_theme.dart';
import '../services/payment_service.dart';
import '../services/api_service.dart';
import '../services/error_handler.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final PaymentService _paymentService = PaymentService();
  late final TextEditingController _amountController;
  bool _isProcessing = false;
  int _selectedPresetAmount = 250;

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    appState.fetchWalletBalance();

    // Default to 0 for new accounts (0 balance), otherwise 250
    final defaultAmount = appState.walletBalance == 0 ? '0' : '250';
    _amountController = TextEditingController(text: defaultAmount);

    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: (response) {},
    );
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final amt = int.tryParse(_amountController.text) ?? 0;
    setState(() {
      if (amt == 250 || amt == 500 || amt == 1000) {
        _selectedPresetAmount = amt;
      } else {
        _selectedPresetAmount = 0; // custom input
      }
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final double amount = double.tryParse(_amountController.text) ?? 0;
      final success = await ApiService.addMoneyToWallet(
        amount,
        response.paymentId ?? '',
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Money added successfully!")),
          );
          Provider.of<AppStateProvider>(
            context,
            listen: false,
          ).fetchWalletBalance();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to credit money to wallet.")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentFailure(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
    setState(() => _isProcessing = false);
  }

  Future<void> _startPayment() async {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return;

    final int amount = int.tryParse(amountText) ?? 0;
    if (amount < 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Minimum amount is ₹100")));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final String razorpayKeyId = dotenv.get(
        'RAZORPAY_KEY_ID',
        fallback: 'rzp_test_YourKeyIDHere',
      );

      final user =
          Provider.of<AppStateProvider>(
            context,
            listen: false,
          ).profileData?['user'];

      final email = user?['email']?.toString() ?? '';
      final contact = user?['phoneNumber']?.toString() ?? '';

      _paymentService.openCheckout(
        keyId: razorpayKeyId,
        orderId: null, // No order ID needed for wallet top-ups
        name: "WILL Wallet",
        description: "Add money to wallet",
        email: email.isNotEmpty ? email : 'support@example.com',
        contact: contact.isNotEmpty ? contact : '9999999999',
        amount: amount * 100, // In paise
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final double balance = appState.walletBalance;

    final int typedAmount = int.tryParse(_amountController.text) ?? 0;
    final double cashback = typedAmount >= 250 ? typedAmount * 0.05 : 0.0;
    final double totalWalletValue = typedAmount + cashback;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => appState.fetchWalletBalance(),
        color: const Color(0xFF4A9782),
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // 1. Bright gradient green header block
                  _buildHeader(context),

                  // Content section shifting slightly upwards onto green header
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // 2. White Balance Card
                          _buildBalanceCard(balance),
                          const SizedBox(height: 16),

                          // 4. White Add Money Container
                          _buildAddMoneyCard(
                            typedAmount,
                            cashback,
                            totalWalletValue,
                          ),
                          const SizedBox(height: 24),

                          // 5. Grid of 3 top-up features
                          _buildFeaturesGrid(),
                          const SizedBox(height: 16),

                          // 6. How it works timeline card
                          _buildHowItWorksCard(),
                          const SizedBox(height: 16),

                          // 7. Using your balance policies card
                          _buildUsingBalanceCard(),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 32,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF4A9782)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      height: 240 + topPadding,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F9B60), // Lighter vibrant green
            Color(0xFF0E8A54), // Deeper green
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(top: topPadding + 12, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Support request details coming soon.'),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Will',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          Text(
            'Wallet',
            style: GoogleFonts.inter(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wallet Balance',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${balance.toInt()}',
            style: GoogleFonts.inter(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF00AA6E), // Bright mockup green
            ),
          ),
          const SizedBox(height: 12),
          Text(
            balance <= 50
                ? 'Your balance is low. Please add money to continue enjoying benefits.'
                : 'Your wallet has active credits. Top up now to secure extra rewards.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMoneyCard(
    int typedAmount,
    double cashback,
    double totalWalletValue,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add money',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // TextField Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      prefixText: '₹',
                      prefixStyle: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (cashback > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Get ₹${cashback.toStringAsFixed(1)} cashback',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Helper dynamic subtext
          if (typedAmount > 0)
            Text(
              typedAmount < 100
                  ? 'Minimum amount to top up is ₹100'
                  : (cashback > 0
                      ? 'You will get ₹${totalWalletValue.toStringAsFixed(1)} in the wallet!'
                      : 'You will get ₹$typedAmount in the wallet! Min ₹250 to unlock cashback.'),
              style: GoogleFonts.inter(
                fontSize: 12,
                color:
                    typedAmount < 100
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 20),

          // Horizontal Custom Chip list
          Row(
            children: [
              _buildPresetTopUpChip(250, '+₹12.5'),
              const SizedBox(width: 10),
              _buildPresetTopUpChip(500, '+₹25'),
              const SizedBox(width: 10),
              _buildPresetTopUpChip(1000, '+₹50'),
            ],
          ),
          const SizedBox(height: 24),

          // Big green top-up button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _startPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AA6E), // Bright top-up green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add ₹$typedAmount to wallet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTopUpChip(int amount, String label) {
    bool isSelected = _selectedPresetAmount == amount;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPresetAmount = amount;
            _amountController.text = amount.toString();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6F4EA) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF137333)
                      : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                '₹$amount',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? const Color(0xFF137333)
                          : const Color(0xFFE8F3F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF4A9782),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Row(
      children: [
        _buildFeatureItem(
          icon: Icons.flash_on_rounded,
          title: 'Earn Rewards',
          subtitle: 'on every top-up',
        ),
        _buildFeatureDivider(),
        _buildFeatureItem(
          icon: Icons.check_circle_outline_rounded,
          title: 'Quick Checkout',
          subtitle: 'on every booking',
        ),
        _buildFeatureDivider(),
        _buildFeatureItem(
          icon: Icons.calendar_today_outlined,
          title: 'Universal Access',
          subtitle: 'on all bookings',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFE6F4EA),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF137333), size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDivider() {
    return Container(height: 32, width: 1, color: const Color(0xFFE2E8F0));
  }

  Widget _buildHowItWorksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),

          // Timeline list
          _buildTimelineStep(
            stepNumber: 1,
            text:
                'Add money to your Will wallet and receive promotional rewards.',
            isLast: false,
          ),
          _buildTimelineStep(
            stepNumber: 2,
            text:
                'Checkout instantly with balance in your Will wallet across all orders.',
            isLast: false,
          ),
          _buildTimelineStep(
            stepNumber: 3,
            text:
                'Wallet balance cannot be withdrawn and can only be used on Will, in accordance with applicable laws.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required int stepNumber,
    required String text,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF0F9B60),
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 48,
                decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsingBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Using your Balance',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          _buildPolicyItem(
            'Seamlessly pay for bookings with balance in your wallet at Pronto.',
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            'Promotional rewards expire 15 days after being credited.',
          ),
          const SizedBox(height: 12),
          _buildPolicyItem(
            'Cash balance expires 1 year from the date of credit.',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Transform.rotate(
            angle: 45 * 3.14159 / 180,
            child: Container(
              width: 6,
              height: 6,
              color: const Color(0xFF0F9B60),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
