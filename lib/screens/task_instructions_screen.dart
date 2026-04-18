import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../models/service_category.dart';
import 'service_request_screen.dart';

class TaskInstructionsScreen extends StatefulWidget {
  final ServiceCategory category;

  const TaskInstructionsScreen({super.key, required this.category});

  @override
  State<TaskInstructionsScreen> createState() => _TaskInstructionsScreenState();
}

class _TaskInstructionsScreenState extends State<TaskInstructionsScreen> {
  int _workerCount = 1;
  String? _selectedWorkType;
  final List<String> _workTypes = [
    'Emergency Repair',
    'Standard Maintenance',
    'New Installation',
    'Periodic Checkup',
    'Other (please specify)'
  ];
  String? _taskImageBase64;
  String? _taskAudioBase64;
  final ImagePicker _picker = ImagePicker();
  
  // Audio state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  
  // Message state
  bool _showMessageField = false;
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _audioRecorder.dispose();
    _msgController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress image to save bandwidth/storage
    );

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _taskImageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  Future<void> _toggleRecording() async {
    try {
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
          final path = '${tempDir.path}/task_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
    setState(() => _workerCount++);
  }

  void _decrementWorkers() {
    if (_workerCount > 1) {
      setState(() => _workerCount--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  _buildWorkTypeDropdown(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                  if (_showMessageField) _buildMessageField(),
                  const SizedBox(height: 40),
                  _buildWorkerSelector(),
                  const Spacer(),
                  _buildNextButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: const BoxDecoration(
        color: Color(0xFF2E876E),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          // Pattern overlay (subtle dots)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Image.asset(
                'assets/images/branding_banner.png', // Fallback to branding banner or similar
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF2E876E), size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'Help the workers understand the task.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBEB),
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedWorkType,
          hint: Text(
            'Select most relevant work type *',
            style: GoogleFonts.inter(
              color: const Color(0xFF636363),
              fontSize: 14,
            ),
          ),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
          items: _workTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, style: GoogleFonts.inter(fontSize: 14)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selectedWorkType = newValue);
          },
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: _buildMediaButton(
            label: _taskImageBase64 != null ? 'Image added' : 'Upload image',
            icon: _taskImageBase64 != null ? Icons.check_circle : Icons.unarchive_outlined,
            isWide: true,
            isSuccess: _taskImageBase64 != null,
          ),
        ),
        const SizedBox(width: 15),
        GestureDetector(
          onTap: () => setState(() => _showMessageField = !_showMessageField),
          child: _buildRoundButton(
            Icons.comment_outlined, 
            isActive: _showMessageField || _msgController.text.isNotEmpty,
          ),
        ),
        const SizedBox(width: 15),
        GestureDetector(
          onTap: _toggleRecording,
          child: _buildRoundButton(
            _isRecording ? Icons.stop : (_taskAudioBase64 != null ? Icons.check : Icons.mic_none_outlined),
            isActive: _isRecording,
            isSuccess: _taskAudioBase64 != null && !_isRecording,
          ),
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: TextField(
          controller: _msgController,
          maxLines: 3,
          style: GoogleFonts.roboto(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Describe the issue or add instructions...',
            hintStyle: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaButton({required String label, required IconData icon, bool isWide = false, bool isSuccess = false}) {
    return Container(
      height: 50,
      width: isWide ? 160 : null,
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFF4A9782) : const Color(0xFF1E6351),
        borderRadius: BorderRadius.circular(15),
        border: isSuccess ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, {bool isActive = false, bool isSuccess = false}) {
    Color bgColor = const Color(0xFF519482);
    if (isActive) bgColor = Colors.redAccent;
    if (isSuccess) bgColor = const Color(0xFF2E876E);

    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
        border: isSuccess ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildWorkerSelector() {
    return Row(
      children: [
        Icon(Icons.person_outline, color: Colors.black.withOpacity(0.7), size: 32),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            'Select the number of Worker',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        Row(
          children: [
            _buildCounterButton(Icons.remove, _decrementWorkers),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                '$_workerCount',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildCounterButton(Icons.add, _incrementWorkers),
          ],
        ),
      ],
    );
  }

  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    bool isPressed = false;
    return StatefulBuilder(
      builder: (context, setStateLocal) {
        return GestureDetector(
          onTapDown: (_) => setStateLocal(() => isPressed = true),
          onTapUp: (_) => setStateLocal(() => isPressed = false),
          onTapCancel: () => setStateLocal(() => isPressed = false),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: 30,
            width: 30,
            decoration: BoxDecoration(
              color: isPressed ? const Color(0xFF519482) : const Color(0xFFD9D9D9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        );
      },
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: 140,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          if (_selectedWorkType == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please select a work type')),
            );
            return;
          }
          if (_selectedWorkType == 'Other (please specify)' && _msgController.text.trim().isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please use the message button to specify the work type')),
            );
            return;
          }
          if (_isRecording) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please stop recording your voice note first')),
            );
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceRequestScreen(
                category: widget.category,
                numberOfWorkers: _workerCount,
                workType: _selectedWorkType!,
                taskImageBase64: _taskImageBase64,
                taskAudioBase64: _taskAudioBase64,
                taskNotes: _msgController.text.isNotEmpty ? _msgController.text : null,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF519482),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}
