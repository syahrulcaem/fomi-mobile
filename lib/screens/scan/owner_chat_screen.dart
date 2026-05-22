import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/chat_model.dart';
import '../../services/notification_service.dart';
import '../../services/qrcode_service.dart';

const _kRed = Color(0xFFD32F2F);
const _kRedLight = Color(0xFFFFEBEE);
const _kBg = Color(0xFFF5F5F5);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF757575);

class OwnerChatScreen extends StatefulWidget {
  const OwnerChatScreen({
    super.key,
    required this.assetId,
    required this.assetName,
    this.initialSessionId,
  });

  final String assetId;
  final String assetName;
  final String? initialSessionId;

  @override
  State<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends State<OwnerChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _loading = false;
  bool _sending = false;
  String? _selectedSessionId;
  Map<String, List<ChatModel>> _chatsBySession = const {};
  Timer? _pollingTimer;
  bool _didInitialLoad = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _loadChats(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChats({bool silent = false, bool notifyOnNew = true}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final service = context.read<QrCodeService>();
      final previous = _chatsBySession;
      final grouped = await service.getAssetChats(widget.assetId);
      if (!mounted) return;

      final sessions = grouped.keys.toList()..sort();
      final prev = _selectedSessionId;
      final preferred = widget.initialSessionId;
      final next = sessions.contains(prev)
          ? prev
          : sessions.contains(preferred)
              ? preferred
              : (sessions.isNotEmpty ? sessions.first : null);

      setState(() {
        _chatsBySession = grouped;
        _selectedSessionId = next;
      });

      if (_didInitialLoad && notifyOnNew) {
        final newCount = _countNewFinderMessages(previous, grouped);
        if (newCount > 0 && mounted) {
          final notif = context.read<NotificationService>();
          await notif.showChatAlert(
            title: 'Pesan baru dari finder',
            body: '$newCount pesan baru pada ${widget.assetName}',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Ada $newCount pesan baru dari finder.',
                  style: GoogleFonts.poppins(fontSize: 13)),
              backgroundColor: _kRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        }
      }

      _didInitialLoad = true;
      _jumpToBottom();
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal memuat chat anonim.',
              style: GoogleFonts.poppins(fontSize: 13)),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted && !silent) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    final sessionId = _selectedSessionId;
    if (message.isEmpty || sessionId == null || _sending) return;

    setState(() => _sending = true);
    _messageController.clear();
    try {
      await context.read<QrCodeService>().replyAssetChat(
            assetId: widget.assetId,
            sessionId: sessionId,
            message: message,
          );
      await _loadChats(silent: true, notifyOnNew: false);
    } catch (_) {
      if (!mounted) return;
      _messageController.text = message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal mengirim balasan.',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  int _countNewFinderMessages(
    Map<String, List<ChatModel>> previous,
    Map<String, List<ChatModel>> current,
  ) {
    final prev = <String>{};
    for (final e in previous.entries) {
      for (final m in e.value) {
        prev.add(_fingerprint(e.key, m));
      }
    }
    var count = 0;
    for (final e in current.entries) {
      for (final m in e.value) {
        if (!prev.contains(_fingerprint(e.key, m)) &&
            m.senderType.toLowerCase() == 'finder') {
          count++;
        }
      }
    }
    return count;
  }

  String _fingerprint(String sessionId, ChatModel msg) {
    if (msg.id.isNotEmpty) return '$sessionId|${msg.id}';
    return '$sessionId|${msg.senderType}|${msg.createdAt ?? ''}|${msg.message}';
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _chatsBySession.keys.toList()..sort();
    final messages = _selectedSessionId == null
        ? const <ChatModel>[]
        : (_chatsBySession[_selectedSessionId] ?? const <ChatModel>[]);

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(sessions),
          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator(color: _kRed)))
          else if (sessions.isEmpty)
            _buildEmpty()
          else ...[
            if (sessions.length > 1) _buildSessionTabs(sessions),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadChats,
                color: _kRed,
                child: messages.isEmpty
                    ? _buildEmptyMessages()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) =>
                            _buildBubble(messages[i]),
                      ),
              ),
            ),
            _buildInputBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(List<String> sessions) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 12,
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
                color: _kRedLight,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 16, color: _kRed),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 38, height: 38,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB71C1C), _kRed],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              widget.assetName.isNotEmpty
                  ? widget.assetName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.assetName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary)),
              Text('${sessions.length} sesi · Chat Anonim',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: _kTextSecondary)),
            ],
          ),
        ),
        // Live indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: _kRedLight,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: _kRed, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('Live',
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kRed)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSessionTabs(List<String> sessions) {
    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final sId = sessions[i];
          final selected = sId == _selectedSessionId;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSessionId = sId);
              _jumpToBottom();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? _kRed : _kBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Sesi ${i + 1}',
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : _kTextSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: _kRedLight,
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                size: 36, color: _kRed),
          ),
          const SizedBox(height: 16),
          Text('Belum ada chat anonim.',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 6),
          Text('Pesan dari finder akan muncul di sini.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _kTextSecondary)),
        ]),
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Text('Belum ada pesan di sesi ini.',
          style: GoogleFonts.poppins(
              fontSize: 13, color: _kTextSecondary)),
    );
  }

  Widget _buildBubble(ChatModel msg) {
    final isOwner = msg.senderType.toLowerCase() == 'owner';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment:
            isOwner ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwner) ...[
            Container(
              width: 28, height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 2),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded,
                  size: 15, color: Colors.grey),
            ),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.70),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isOwner ? _kRed : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      isOwner ? const Radius.circular(18) : Radius.zero,
                  bottomRight:
                      isOwner ? Radius.zero : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isOwner
                        ? _kRed.withOpacity(0.25)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isOwner
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOwner ? 'Anda' : 'Finder',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: isOwner
                          ? Colors.white70
                          : _kRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(msg.message,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isOwner ? Colors.white : _kTextPrimary,
                          height: 1.4)),
                ],
              ),
            ),
          ),
          if (isOwner) ...[
            Container(
              width: 28, height: 28,
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

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            minLines: 1,
            maxLines: 4,
            style: GoogleFonts.poppins(fontSize: 13, color: _kTextPrimary),
            decoration: InputDecoration(
              hintText: 'Balas ke finder...',
              hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _kTextSecondary.withOpacity(0.5)),
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
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _sending ? null : _send,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: _sending
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFB71C1C), _kRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: _sending ? Colors.grey.shade200 : null,
              shape: BoxShape.circle,
              boxShadow: _sending
                  ? []
                  : [
                      BoxShadow(
                          color: _kRed.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ],
            ),
            child: _sending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kRed))
                : const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }
}
