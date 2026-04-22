import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  final String bookingId;
  final String receiverName;
  final String? receiverImage;

  const ChatScreen({
    super.key,
    required this.bookingId,
    required this.receiverName,
    this.receiverImage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  Timer? _pollingTimer;
  bool _isLoading = true;
  String? _myId;

  @override
  void initState() {
    super.initState();
    _loadMyId();
    _fetchMessages();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMyId() async {
    // In a real app, you'd get this from a UserProvider
    // For now, we'll fetch it from profile or assume sender populate handles it
    final profile = await ApiService.getProfile();
    if (mounted) {
      setState(() {
        _myId = profile['_id'];
      });
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages(showLoading: false);
    });
  }

  Future<void> _fetchMessages({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    try {
      final messages = await ApiService.getMessages(widget.bookingId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        if (showLoading) {
           _scrollToBottom();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final sentMessage = await ApiService.sendMessage(widget.bookingId, text);
    if (sentMessage != null) {
      setState(() {
        _messages.add(sentMessage);
      });
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF4A9782).withOpacity(0.1),
              backgroundImage: widget.receiverImage != null && widget.receiverImage!.isNotEmpty
                  ? NetworkImage(widget.receiverImage!)
                  : null,
              child: widget.receiverImage == null || widget.receiverImage!.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF4A9782), size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: GoogleFonts.roboto(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Online',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF4A9782),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A9782)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['sender']['_id'] == _myId;
                      return _buildMessageBubble(msg['text'], isMe);
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF4A9782) : const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.roboto(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF4A9782),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
