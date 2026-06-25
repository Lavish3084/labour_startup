import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/service_category.dart';
import '../widgets/concave_header_clipper.dart';
import 'service_request_screen.dart';

enum DescribeMode { photo, voice, text }

class TaskInstructionsScreen extends StatefulWidget {
  final ServiceCategory category;
  final bool isInstant;

  const TaskInstructionsScreen({
    super.key,
    required this.category,
    this.isInstant = false,
  });

  @override
  State<TaskInstructionsScreen> createState() => _TaskInstructionsScreenState();
}

class _TaskInstructionsScreenState extends State<TaskInstructionsScreen>
    with SingleTickerProviderStateMixin {
  int _workerCount = 1;
  String? _selectedWorkType;
  late final AnimationController _selectorAnimController;
  late final Animation<double> _chevronRotation;

  static const List<String> _workTypes = [
    'Emergency Repair',
    'Standard Maintenance',
    'New Installation',
    'Periodic Checkup',
    'Other (please specify)',
  ];
  final List<String> _taskImagesBase64 = [];
  String? _taskAudioBase64;
  final ImagePicker _picker = ImagePicker();

  // Audio state
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecording = false;
  bool _isPlaying = false;

  // Message state
  final TextEditingController _msgController = TextEditingController();

  // Active Describe Mode
  DescribeMode _activeDescribeMode = DescribeMode.voice;

  @override
  void initState() {
    super.initState();
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
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
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

  Future<void> _showWorkTypePicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _WorkTypePickerSheet(
            options: _workTypes,
            selected: _selectedWorkType,
          ),
    );
    if (picked != null && mounted) {
      setState(() => _selectedWorkType = picked);
      _selectorAnimController.forward();
    }
  }

  Future<void> _showImagePickerBottomSheet() async {
    if (_taskImagesBase64.length >= 5) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 5 images allowed')));
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: Color(0xFF468A73),
                  ),
                  title: Text('Take a Photo', style: GoogleFonts.inter()),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: Color(0xFF468A73),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(),
                  ),
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 50, // Compress image to save bandwidth/storage
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _taskImagesBase64.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      });
    }
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
      if (_taskAudioBase64 != null) {
        if (_isPlaying) {
          await _audioPlayer.stop();
        }
        return;
      }

      // Recording logic
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() => _isRecording = false);
        if (path != null) {
          final bytes = await File(path).readAsBytes();
          setState(() {
            _taskAudioBase64 = 'data:audio/m4a;base64,${base64Encode(bytes)}';
          });
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
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Microphone permission required')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Audio recording error: $e');
      setState(() => _isRecording = false);
    }
  }

  void _incrementWorkers() {
    if (_workerCount < 6) {
      setState(() => _workerCount++);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 6 workers allowed per request'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _decrementWorkers() {
    if (_workerCount > 1) {
      setState(() => _workerCount--);
    }
  }

  static const double _headerHeight = 280;
  static const double _sheetOverlapTop = 236;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    const bottomBarPadding = 88.0;

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
                        bottomPadding: bottomBarPadding + bottomInset,
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
                child: _buildBottomBar(bottomInset),
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
        color: const Color(0xFFFCFCFC),
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
            padding: EdgeInsets.fromLTRB(24, 20, 24, bottomPadding),
            child: Column(
              children: [
                _buildWorkTypeDropdown(),
                const SizedBox(height: 24),
                _buildDescribeSection(),
                const SizedBox(height: 24),
                _buildWorkerSelector(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(double bottomInset) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFCFC),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 16),
      child: _buildNextButton(),
    );
  }

  Widget _buildHeaderBackButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            height: 38,
            width: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: Color(0xFF2E876E),
              size: 20,
            ),
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
            Positioned.fill(child: CustomPaint(painter: DotPatternPainter())),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Help the workers\nunderstand the task.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkTypeDropdown() {
    final hasSelection = _selectedWorkType != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _showWorkTypePicker,
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEBEBEB),
            borderRadius: BorderRadius.circular(30),
            border:
                hasSelection
                    ? Border.all(color: const Color(0xFF4A9782), width: 1.2)
                    : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight:
                        hasSelection ? FontWeight.w600 : FontWeight.w500,
                    color:
                        hasSelection ? Colors.black : const Color(0xFF6F6F6F),
                  ),
                  child: Text(
                    hasSelection
                        ? _selectedWorkType!
                        : 'Select most relevant work type *',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              RotationTransition(
                turns: _chevronRotation,
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.black87,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescribeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe the problem (Optional)',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDescribeModeButton(
                mode: DescribeMode.photo,
                label: 'Photo',
                icon: Icons.camera_alt_outlined,
              ),
              _buildDescribeModeButton(
                mode: DescribeMode.voice,
                label: 'Voice Note',
                icon: Icons.mic,
              ),
              _buildDescribeModeButton(
                mode: DescribeMode.text,
                label: 'Text',
                icon: Icons.chat_bubble_outline,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDynamicInputArea(),
        ],
      ),
    );
  }

  Widget _buildDescribeModeButton({
    required DescribeMode mode,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _activeDescribeMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() {
          _activeDescribeMode = mode;
        });
      },
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? const Color(0xFF468A73)
                      : const Color(0xFFEBEBEB),
              shape: BoxShape.circle,
              boxShadow:
                  isSelected
                      ? [
                        BoxShadow(
                          color: const Color(0xFF468A73).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : [],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF666666),
              size: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color:
                  isSelected
                      ? const Color(0xFF468A73)
                      : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicInputArea() {
    switch (_activeDescribeMode) {
      case DescribeMode.photo:
        return _buildPhotoArea();
      case DescribeMode.voice:
        return _buildVoiceArea();
      case DescribeMode.text:
        return _buildTextArea();
    }
  }

  Widget _buildDashedTargetArea({
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFFCCCCCC),
          borderRadius: 12,
          dashWidth: 6,
          dashSpace: 4,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.attach_file, color: Color(0xFF888888), size: 28),
              const SizedBox(height: 12),
              Text(
                text,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF888888),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoArea() {
    if (_taskImagesBase64.isEmpty) {
      return _buildDashedTargetArea(
        text: 'Add media or text to describe the task clearly.',
        onTap: _showImagePickerBottomSheet,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount:
                _taskImagesBase64.length +
                (_taskImagesBase64.length < 5 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _taskImagesBase64.length) {
                return GestureDetector(
                  onTap: _showImagePickerBottomSheet,
                  child: Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Color(0xFF757575),
                    ),
                  ),
                );
              }

              final imgBase64 = _taskImagesBase64[index];
              final bytes = base64Decode(imgBase64.split(',').last);
              return Stack(
                children: [
                  GestureDetector(
                    onTap: () => _previewImage(imgBase64),
                    child: Container(
                      width: 90,
                      height: 90,
                      margin: const EdgeInsets.only(right: 10),
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
                    right: 14,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _taskImagesBase64.removeAt(index);
                        });
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
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '${_taskImagesBase64.length}/5 Images uploaded',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceArea() {
    if (_isRecording) {
      return CustomPaint(
        painter: DashedBorderPainter(
          color: const Color(0xFF468A73),
          borderRadius: 12,
          dashWidth: 6,
          dashSpace: 4,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            children: [
              const Icon(Icons.mic, color: Colors.redAccent, size: 30),
              const SizedBox(height: 10),
              Text(
                'Recording audio note...',
                style: GoogleFonts.inter(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _toggleAudioAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  'STOP',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_taskAudioBase64 != null) {
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
              onTap: () async {
                if (_isPlaying) {
                  await _audioPlayer.stop();
                } else {
                  final bytes = base64Decode(_taskAudioBase64!.split(',').last);
                  await _audioPlayer.stop();
                  await _audioPlayer.release();
                  await _audioPlayer.play(BytesSource(bytes));
                }
              },
              child: Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF468A73),
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
                _isPlaying ? 'Playing audio note...' : 'Voice note recorded',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF333333),
                  fontSize: 14,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _taskAudioBase64 = null;
                  _isPlaying = false;
                });
                _audioPlayer.stop();
              },
            ),
          ],
        ),
      );
    }

    return _buildDashedTargetArea(
      text: 'Add media or text to describe the task clearly.',
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
        maxLines: 4,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Add text message or special instructions...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF9E9E9E),
            fontSize: 13,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
        onChanged: (val) {
          setState(() {});
        },
      ),
    );
  }

  Widget _buildWorkerSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.group_outlined, color: Color(0xFF468A73), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'How many\nworkers do you\nneed?',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
                height: 1.3,
              ),
            ),
          ),
          Row(
            children: [
              _buildCounterButton(Icons.remove, _decrementWorkers),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$_workerCount',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              _buildCounterButton(Icons.add, _incrementWorkers),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFABDEC3), width: 1.5),
        ),
        child: Icon(icon, color: const Color(0xFF2E876E), size: 20),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (_selectedWorkType == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a work type')),
            );
            return;
          }
          if (_selectedWorkType == 'Other (please specify)' &&
              _msgController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please add a description to specify the work type',
                ),
              ),
            );
            return;
          }
          if (_isRecording) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please stop recording your voice note first'),
              ),
            );
            return;
          }

          if (_isPlaying) {
            _audioPlayer.stop();
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ServiceRequestScreen(
                    category: widget.category,
                    isInstant: widget.isInstant,
                    numberOfWorkers: _workerCount,
                    workType: _selectedWorkType!,
                    taskImagesBase64:
                        _taskImagesBase64.isNotEmpty ? _taskImagesBase64 : null,
                    taskAudioBase64: _taskAudioBase64,
                    taskNotes:
                        _msgController.text.isNotEmpty
                            ? _msgController.text
                            : null,
                  ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A9782),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'NEXT',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

class _WorkTypePickerSheet extends StatefulWidget {
  final List<String> options;
  final String? selected;

  const _WorkTypePickerSheet({required this.options, required this.selected});

  @override
  State<_WorkTypePickerSheet> createState() => _WorkTypePickerSheetState();
}

class _WorkTypePickerSheetState extends State<_WorkTypePickerSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Animation<double> _itemAnim(int index) {
    final start = (index * 0.08).clamp(0.0, 0.55);
    final end = (start + 0.42).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  void _selectOption(String label) {
    Navigator.pop(context, label);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Select most relevant work type',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: widget.options.length,
                  itemBuilder: (context, index) {
                    final label = widget.options[index];
                    final isSelected = widget.selected == label;
                    final anim = _itemAnim(index);

                    return AnimatedBuilder(
                      animation: anim,
                      builder: (context, child) {
                        final t = anim.value;
                        return Transform.translate(
                          offset: Offset(0, 16 * (1 - t)),
                          child: Opacity(opacity: t, child: child),
                        );
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _selectOption(label),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? const Color(0xFFEBEBEB)
                                      : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    label,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check,
                                    color: Color(0xFF468A73),
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Painter for subtle dots pattern behind the curved green header
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.08)
          ..style = PaintingStyle.fill;

    const double spacing = 18.0;
    const double radius = 2.0;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter to draw a dashed border around container for the dynamic input area
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1,
    this.dashWidth = 5,
    this.dashSpace = 3,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Radius.circular(borderRadius),
          ),
        );

    final dashPath = Path();
    for (final PathMetric pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        final double length = dashWidth;
        if (distance + length > pathMetric.length) {
          dashPath.addPath(
            pathMetric.extractPath(distance, pathMetric.length),
            Offset.zero,
          );
        } else {
          dashPath.addPath(
            pathMetric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
