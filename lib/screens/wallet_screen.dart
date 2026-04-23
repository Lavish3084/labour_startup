import 'package:flutter/material.dart';
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
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentFailure,
      onExternalWallet: (response) {},
    );
  }

  @override
  void dispose() {
    _paymentService.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessing = true);
    try {
      final double amount = double.tryParse(_amountController.text) ?? 0;
      final success = await ApiService.verifyWalletPayment(
        response.orderId!,
        response.paymentId!,
        response.signature!,
        amount,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Money added successfully!")),
          );
          Provider.of<AppStateProvider>(context, listen: false).fetchWalletBalance();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment verification failed.")),
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
    if (amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Minimum amount is ₹10")),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final String razorpayKeyId = dotenv.get(
        'RAZORPAY_KEY_ID',
        fallback: 'rzp_test_YourKeyIDHere',
      );

      final order = await ApiService.createWalletOrder(amount);
      final user = Provider.of<AppStateProvider>(context, listen: false).profileData?['user'];

      _paymentService.openCheckout(
        keyId: razorpayKeyId,
        orderId: order['id'],
        name: "WILL Wallet",
        description: "Add money to wallet",
        email: user?['email'] ?? "user@example.com",
        contact: user?['phone'] ?? "9876543210",
        amount: order['amount'],
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getErrorMessage(e))),
        );
      }
    }
  }

  void _showAddMoneyDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 32,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Money to Wallet',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the amount you want to add',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF595959),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4A9782),
              ),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4A9782),
                ),
                hintText: '0',
                filled: true,
                fillColor: const Color(0xFFF9F9F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [100, 200, 500].map((val) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('₹$val'),
                  selected: _amountController.text == val.toString(),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _amountController.text = val.toString());
                      Navigator.pop(context);
                      _showAddMoneyDialog(); // Re-open to update state (simple way)
                    }
                  },
                  selectedColor: const Color(0xFF4A9782).withOpacity(0.1),
                  labelStyle: GoogleFonts.roboto(
                    color: const Color(0xFF4A9782),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startPayment();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9782),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Proceed to Pay',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final double balance = appState.walletBalance;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Wallet',
          style: GoogleFonts.roboto(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D1B20),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => appState.fetchWalletBalance(),
        color: const Color(0xFF4A9782),
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(balance),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                  const SizedBox(height: 32),
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityList(appState),
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

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Available Balance',
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF595959),
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: GoogleFonts.roboto(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4A9782),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Add Money',
            icon: Icons.add_circle_outline_rounded,
            backgroundColor: const Color(0xFF4A9782),
            textColor: Colors.white,
            onTap: _showAddMoneyDialog,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'Withdraw',
            icon: Icons.arrow_upward_rounded,
            backgroundColor: Colors.white,
            textColor: Colors.grey, // Disabled look
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Withdrawals are not permitted at this time.')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: backgroundColor == Colors.white 
            ? Border.all(color: const Color(0xFFEEEEEE)) 
            : null,
          boxShadow: backgroundColor == Colors.white ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(AppStateProvider appState) {
    final List<dynamic> transactions = appState.walletTransactions;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(Icons.history_rounded, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No recent activity',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: const Color(0xFF595959),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildActivityItem(tx);
      },
    );
  }

  Widget _buildActivityItem(dynamic tx) {
    final bool isCredit = tx['type']?.toString().toLowerCase() == 'credit';
    final String amount = (isCredit ? '+' : '-') + '₹${tx['amount']}';
    
    // Formatting date
    String dateStr = 'Recently';
    try {
      final DateTime date = DateTime.parse(tx['date']).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = "${date.day} ${months[date.month - 1]}, ${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.add_card_rounded : Icons.account_balance_wallet_outlined, 
              color: const Color(0xFF595959), 
              size: 24
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx['title'] ?? (isCredit ? 'Money Added' : 'Service Booking'),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF595959),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isCredit ? const Color(0xFF4A9782) : const Color(0xFF1D1B20),
            ),
          ),
        ],
      ),
    );
  }
}
