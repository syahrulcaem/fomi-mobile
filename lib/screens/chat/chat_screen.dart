import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/chat_model.dart';
import '../../services/qr_service.dart';

const _kRed = Color(0xFFD32F2F);
const _kRedLight = Color(0xFFFFEBEE);
const _kBg = Color(0xFFF5F5F5);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF757575);

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.code,
    required this.sessionId,
  });

  final String code;
  final String sessionId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await context.read<QrService>().getFinderChats(
            code: widget.code,
            sessionId: widget.sessionId,
          );
      if (!mounted) return;
      setState(() => _messages = data);
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat chat: $e',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await context.read<QrService>().sendFinderMessage(
            code: widget.code,
            sessionId: widget.sessionId,
            message: message,
          );
      await _loadMessages();
    } catch (e) {
      if (!mounted) return;
      // Restore message on failure
      _messageController.text = message;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal kirim pesan: $e',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: _kRed))
                : _messages.isEmpty
                    ? _buildEmpty()
                    : _buildMessageList(),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kRedLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.arrow_back_ios_new, size: 16, color: _kRed),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB71C1C), _kRed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.chat_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Obrolan',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _kTextPrimary,
                  ),
                ),
                Text(
                  widget.sessionId.length > 12
                      ? '${widget.sessionId.substring(0, 12)}…'
                      : widget.sessionId,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Refresh
          GestureDetector(
            onTap: _isLoading ? null : _loadMessages,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _kRedLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kRed))
                  : const Icon(Icons.refresh_rounded, size: 18, color: _kRed),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _kRedLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 36, color: _kRed),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada obrolan nih!',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kirim pesan pertamamu di bawah.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: _kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final chat = _messages[index];
        final isMe = chat.senderType == 'finder';
        return _buildBubble(chat, isMe);
      },
    );
  }

  Widget _buildBubble(ChatModel chat, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 15, color: Colors.grey),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _kRed : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe
                        ? _kRed.withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isMe ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                chat.message,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isMe ? Colors.white : _kTextPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isMe) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(left: 8, bottom: 2),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB71C1C), _kRed],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded,
                  size: 15, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  // ── Input bar ─────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              style: GoogleFonts.poppins(fontSize: 13, color: _kTextPrimary),
              decoration: InputDecoration(
                hintText: 'Tulis pesanmu...',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 13, color: _kTextSecondary.withOpacity(0.5)),
                filled: true,
                fillColor: _kBg,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: _kRed, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: _isSending
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFB71C1C), _kRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: _isSending ? Colors.grey.shade200 : null,
                shape: BoxShape.circle,
                boxShadow: _isSending
                    ? []
                    : [
                        BoxShadow(
                            color: _kRed.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kRed))
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
