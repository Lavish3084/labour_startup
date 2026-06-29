import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

import '../providers/cart_provider.dart';
import '../models/cart_item.dart';
import '../utils/app_theme.dart';
import '../services/api_service.dart';
import '../providers/location_provider.dart';
import '../services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/app_state_provider.dart';
import 'location_search_screen.dart';
import 'searching_worker_screen.dart';

enum DescribeMode { photo, voice, text }

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  double _commissionPercentage = 10.0;
  bool _isCheckingOut = false;
  late PaymentService _paymentService;
  List<String> _generatedBookingIds = [];
  bool _useWallet = false;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
    _paymentService = PaymentService();
    _paymentService.initialize(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppStateProvider>(
        context,
        listen: false,
      ).fetchWalletBalance();
    });
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (_generatedBookingIds.isEmpty) return;

    setState(() => _isCheckingOut = true);
    try {
      final success = await ApiService.verifyCartPayment(
        response.orderId!,
        response.paymentId!,
        response.signature!,
        _generatedBookingIds,
      );

      if (success) {
        if (!mounted) return;
        _navigateToNextScreen();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment verification failed. Please contact support.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isCheckingOut = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External Wallet Selected: ${response.walletName}'),
      ),
    );
  }

  void _navigateToNextScreen() {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final items = cartProvider.items;
    if (items.isEmpty) return;

    // Grab the first item's details for the SearchingWorkerScreen
    final firstItem = items.first;
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    final address = locationProvider.currentAddress ?? 'Unknown Address';
    final lat = locationProvider.currentLatitude ?? 0.0;
    final lng = locationProvider.currentLongitude ?? 0.0;
    
    // Pass the first generated booking ID
    final firstBookingId = _generatedBookingIds.isNotEmpty ? _generatedBookingIds.first : null;

    cartProvider.clearCart();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SearchingWorkerScreen(
          category: firstItem.category,
          address: address,
          scheduledTime: firstItem.scheduledDate != null && firstItem.scheduledTime != null
              ? DateTime(firstItem.scheduledDate!.year, firstItem.scheduledDate!.month, firstItem.scheduledDate!.day, firstItem.scheduledTime!.hour, firstItem.scheduledTime!.minute)
              : DateTime.now().add(const Duration(hours: 1)),
          latitude: lat,
          longitude: lng,
          bookingData: firstBookingId != null ? {'_id': firstBookingId} : null,
        ),
      ),
    );
  }

  Future<void> _handleCheckout(CartProvider cartProvider, LocationProvider locProvider) async {
    if (cartProvider.items.isEmpty) return;
    
    final address = locProvider.currentAddress;
    if (address == null || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an address first')),
      );
      return;
    }

    setState(() {
      _isCheckingOut = true;
      _generatedBookingIds.clear();
    });

    try {
      // 1. Create all bookings in backend
      for (final item in cartProvider.items) {
        final result = await ApiService.createBooking(
          category: item.category.name,
          date: item.scheduledDate != null && item.scheduledTime != null
              ? DateTime(item.scheduledDate!.year, item.scheduledDate!.month, item.scheduledDate!.day, item.scheduledTime!.hour, item.scheduledTime!.minute)
              : DateTime.now().add(const Duration(hours: 1)),
          bookingMode: item.isInstant ? 'Hourly' : 'Scheduled', // Assuming hourly by default or mapped
          numberOfHours: (item.durationMinutes / 60).ceil(),
          notes: item.taskNotes,
          taskImages: item.taskImagesBase64,
          taskAudio: item.taskAudioBase64,
          address: address,
          latitude: locProvider.currentLatitude ?? 0.0,
          longitude: locProvider.currentLongitude ?? 0.0,
          amount: item.getBookingAmount(_commissionPercentage).toDouble(),
          numberOfWorkers: item.workerCount,
          workType: item.workType ?? item.category.name,
        );

        if (result['success']) {
          _generatedBookingIds.add(result['data']['_id']);
        } else {
          throw Exception(result['message'] ?? 'Failed to create a booking');
        }
      }

      // 2. Calculate Total Fee
      final totalFeeAmount = cartProvider.getTotalBookingAmount(_commissionPercentage);

      if (totalFeeAmount <= 0) {
        // Free bookings loop
        for (final bId in _generatedBookingIds) {
          await ApiService.confirmFreeBooking(bId);
        }
        _navigateToNextScreen();
      } else if (_useWallet) {
        // Pay Cart with Wallet
        final success = await ApiService.payCartWithWallet(_generatedBookingIds);
        if (success) {
          _navigateToNextScreen();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to pay with wallet. Please try again.')),
          );
        }
      } else {
        // Razorpay Order
        final orderData = await ApiService.createCartPaymentOrder(_generatedBookingIds);
        
        final String razorpayKeyId = dotenv.get('RAZORPAY_KEY_ID', fallback: '');

        final appState = Provider.of<AppStateProvider>(context, listen: false);
        final user = appState.profileData?['user'];
        final email = user?['email']?.toString() ?? '';
        final contact = user?['phoneNumber']?.toString() ?? '';

        _paymentService.openCheckout(
          keyId: razorpayKeyId,
          orderId: orderData['id'],
          name: 'Labour App',
          description: 'Cart Booking Fee',
          email: email.isNotEmpty ? email : 'support@example.com',
          contact: contact.isNotEmpty ? contact : '9999999999',
          amount: totalFeeAmount * 100, // paise
        );
      }
    } catch (e) {
      setState(() => _isCheckingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchSettings() async {
    try {
      // Import ApiService if needed
      final settings = await ApiService.getSettings();
      if (settings.containsKey('adminCommissionPercentage') && settings['adminCommissionPercentage'] != null) {
        if (mounted) {
          setState(() {
            _commissionPercentage = double.tryParse(settings['adminCommissionPercentage'].toString()) ?? 10.0;
          });
        }
      }
    } catch (e) {
      // Ignore settings fetch error
    } finally {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Your Cart',
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final totalPrice = cartProvider.totalPrice.toInt();
          final bookingAmount = cartProvider.getTotalBookingAmount(_commissionPercentage);
          final remainingAmount = totalPrice > bookingAmount ? totalPrice - bookingAmount : 0;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (context, index) {
                    final item = cartProvider.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: CartItemCard(item: item),
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address Selection
                    Consumer<LocationProvider>(
                      builder: (context, locProvider, child) {
                        final address = locProvider.currentAddress;
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LocationSearchScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1FAF7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.brandGreenMain.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: AppTheme.brandGreenMain),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Service Location',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        address != null && address.isNotEmpty
                                            ? address
                                            : 'Select your address',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.black54),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Wallet Section
                    Consumer<AppStateProvider>(
                      builder: (context, appState, child) {
                        final walletBalance = appState.walletBalance;
                        final totalFeeAmount = cartProvider.getTotalBookingAmount(_commissionPercentage);
                        final hasEnoughBalance = walletBalance >= totalFeeAmount;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9F9F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet,
                                  color: AppTheme.brandGreenMain,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pay with Wallet',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      'Balance: ₹${walletBalance.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: hasEnoughBalance ? const Color(0xFF4A9782) : Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _useWallet,
                                onChanged: hasEnoughBalance
                                    ? (val) {
                                        setState(() {
                                          _useWallet = val;
                                        });
                                      }
                                    : null,
                                activeColor: AppTheme.brandGreenMain,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Booking Amount',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹$bookingAmount',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pay ₹$remainingAmount directly to worker',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.brandGreenMain,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: _isCheckingOut ? null : () {
                            final locProvider = Provider.of<LocationProvider>(context, listen: false);
                            _handleCheckout(cartProvider, locProvider);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandGreenMain,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isCheckingOut 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  'Checkout',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CartItemCard extends StatefulWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard>
    with SingleTickerProviderStateMixin {
  late CartItem _item;
  late TextEditingController _msgController;
  DescribeMode? _activeDescribeMode;

  late AnimationController _selectorAnimController;
  late final Animation<double> _chevronRotation;

  static const List<String> _workTypes = [
    'Emergency Repair',
    'Standard Maintenance',
    'New Installation',
    'Periodic Checkup',
    'Other (please specify)',
  ];

  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _msgController = TextEditingController();
    _activeDescribeMode = DescribeMode.photo;
    if (_item.taskNotes != null) {
      _msgController.text = _item.taskNotes!;
    }

    _selectorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _chevronRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _selectorAnimController,
        curve: Curves.easeOutCubic,
      ),
    );
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  @override
  void dispose() {
    _selectorAnimController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _msgController.dispose();
    super.dispose();
  }

  void _updateItem() {
    _item.taskNotes =
        _msgController.text.isNotEmpty ? _msgController.text : null;
    Provider.of<CartProvider>(context, listen: false).updateItem(_item);
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 50,
    );
    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _item.taskImagesBase64.add(
          'data:image/jpeg;base64,${base64Encode(bytes)}',
        );
      });
      _updateItem();
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _previewImage(String imgBase64) {
    final bytes = base64Decode(imgBase64.split(',').last);
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
          ),
    );
  }

  Future<void> _toggleAudioAction() async {
    try {
      if (_item.taskAudioBase64 != null) {
        if (_isPlaying) {
          await _audioPlayer.stop();
        } else {
          final bytes = base64Decode(_item.taskAudioBase64!.split(',').last);
          await _audioPlayer.stop();
          await _audioPlayer.play(BytesSource(bytes));
        }
        return;
      }

      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          final bytes = await File(path).readAsBytes();
          setState(() {
            _item.taskAudioBase64 =
                'data:audio/m4a;base64,${base64Encode(bytes)}';
          });
          _updateItem();
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}/task_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
          setState(() => _isRecording = true);
        }
      }
    } catch (e) {
      setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleText =
        _item.isInstant
            ? "Instant Booking"
            : (_item.scheduledDate != null && _item.scheduledTime != null
                ? "${DateFormat('MMM dd').format(_item.scheduledDate!)}, ${_item.scheduledTime!.format(context)}"
                : "Schedule Pending");

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Price, Remove button
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _item.category.name,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${_item.durationMinutes} minutes  •  $scheduleText",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${_item.totalPrice.toInt()}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.brandGreenMain,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap:
                      () => Provider.of<CartProvider>(
                        context,
                        listen: false,
                      ).removeItem(_item.id),
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Task Instructions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work Type: ${_item.workType ?? "Not specified"}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.brandGreenMain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Help workers understand the task',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPhotoArea(),
                const SizedBox(height: 12),
                _buildDescribeSection(),
                const SizedBox(height: 20),
                _buildWorkerSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Builders adapted from TaskInstructionsScreen ---

  Widget _buildDescribeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDescribeModeButton(
              DescribeMode.photo,
              'Photo',
              Icons.camera_alt_outlined,
            ),
            _buildDescribeModeButton(DescribeMode.voice, 'Voice', Icons.mic),
            _buildDescribeModeButton(
              DescribeMode.text,
              'Text',
              Icons.chat_bubble_outline,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildDynamicInputArea(),
      ],
    );
  }

  Widget _buildDescribeModeButton(
    DescribeMode mode,
    String label,
    IconData icon,
  ) {
    final isSelected = _activeDescribeMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _activeDescribeMode = mode);
        if (mode == DescribeMode.photo) {
          _showPhotoSourceSheet();
        }
      },
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? AppTheme.brandGreenMain
                      : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.brandGreenMain : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicInputArea() {
    if (_activeDescribeMode == DescribeMode.voice) return _buildVoiceArea();
    if (_activeDescribeMode == DescribeMode.text) return _buildTextArea();
    return const SizedBox.shrink();
  }

  Widget _buildPhotoArea() {
    if (_item.taskImagesBase64.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount:
            _item.taskImagesBase64.length +
            (_item.taskImagesBase64.length < 5 ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _item.taskImagesBase64.length) {
            return GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: const Icon(
                  Icons.add_a_photo_outlined,
                  color: Colors.grey,
                ),
              ),
            );
          }
          final imgBase64 = _item.taskImagesBase64[index];
          final bytes = base64Decode(imgBase64.split(',').last);
          return Stack(
            children: [
              GestureDetector(
                onTap: () => _previewImage(imgBase64),
                child: Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: MemoryImage(bytes),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _item.taskImagesBase64.removeAt(index));
                    _updateItem();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVoiceArea() {
    if (_isRecording) {
      return CustomPaint(
        painter: DashedBorderPainter(color: Colors.redAccent),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.mic, color: Colors.redAccent, size: 28),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _toggleAudioAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text(
                  'STOP RECORDING',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_item.taskAudioBase64 != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F9F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD5EAE3)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleAudioAction,
              child: Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  color: AppTheme.brandGreenMain,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isPlaying ? 'Playing...' : 'Voice note recorded',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                setState(() => _item.taskAudioBase64 = null);
                _updateItem();
              },
            ),
          ],
        ),
      );
    }
    return _buildDashedTargetArea(
      text: 'Tap to record voice note.',
      onTap: _toggleAudioAction,
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: _msgController,
        maxLines: 3,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Add text instructions...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (_) => _updateItem(),
      ),
    );
  }

  Widget _buildWorkerSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Number of workers',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            _buildCounterButton(Icons.remove, () {
              if (_item.workerCount > 1) {
                setState(() => _item.workerCount--);
                _updateItem();
              }
            }),
            Container(
              width: 32,
              alignment: Alignment.center,
              child: Text(
                '${_item.workerCount}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildCounterButton(Icons.add, () {
              if (_item.workerCount < 6) {
                setState(() => _item.workerCount++);
                _updateItem();
              }
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.brandGreenMain),
        ),
        child: Icon(icon, color: AppTheme.brandGreenMain, size: 16),
      ),
    );
  }

  Widget _buildDashedTargetArea({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            children: [
              const Icon(Icons.attach_file, color: Colors.grey, size: 24),
              const SizedBox(height: 8),
              Text(
                text,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorkTypePickerSheet extends StatefulWidget {
  final List<String> options;
  final String? selected;

  const WorkTypePickerSheet({
    super.key,
    required this.options,
    required this.selected,
  });

  @override
  State<WorkTypePickerSheet> createState() => _WorkTypePickerSheetState();
}

class _WorkTypePickerSheetState extends State<WorkTypePickerSheet> {

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Select work type',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final label = widget.options[index];
                final isSelected = widget.selected == label;
                return ListTile(
                  title: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  trailing:
                      isSelected
                          ? const Icon(
                            Icons.check,
                            color: AppTheme.brandGreenMain,
                          )
                          : null,
                  onTap: () => Navigator.pop(context, label),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  DashedBorderPainter({this.color = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(12),
          ),
        );
    final dashPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + 5),
          Offset.zero,
        );
        distance += 5 + 3;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
