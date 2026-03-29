import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/chat_model.dart';
import '../../services/notification_service.dart';
import '../../services/qrcode_service.dart';

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
      if (mounted) {
        _loadChats(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChats({
    bool silent = false,
    bool notifyOnNew = true,
  }) async {
    if (!silent) {
      setState(() => _loading = true);
    }

    try {
      final service = context.read<QrCodeService>();
      final previous = _chatsBySession;
      final grouped = await service.getAssetChats(widget.assetId);
      if (!mounted) {
        return;
      }

      final sessions = grouped.keys.toList();
      sessions.sort();

      final previousSession = _selectedSessionId;
      final preferredSession = widget.initialSessionId;
      final nextSelected = sessions.contains(previousSession)
          ? previousSession
          : sessions.contains(preferredSession)
              ? preferredSession
              : (sessions.isNotEmpty ? sessions.first : null);

      setState(() {
        _chatsBySession = grouped;
        _selectedSessionId = nextSelected;
      });

      if (_didInitialLoad && notifyOnNew) {
        final newFinderCount = _countNewFinderMessages(previous, grouped);
        if (newFinderCount > 0 && mounted) {
          final notif = context.read<NotificationService>();
          await notif.showChatAlert(
            title: 'Pesan baru dari finder',
            body: '$newFinderCount pesan baru pada ${widget.assetName}',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ada $newFinderCount pesan baru dari finder.'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      }

      _didInitialLoad = true;

      _jumpToBottom();
    } catch (_) {
      if (!mounted) {
        return;
      }
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat chat anonim.')),
        );
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _send() async {
    final message = _messageController.text.trim();
    final sessionId = _selectedSessionId;

    if (message.isEmpty || sessionId == null) {
      return;
    }

    setState(() => _sending = true);
    try {
      final service = context.read<QrCodeService>();
      await service.replyAssetChat(
        assetId: widget.assetId,
        sessionId: sessionId,
        message: message,
      );
      _messageController.clear();
      await _loadChats(silent: true, notifyOnNew: false);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim balasan.')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  int _countNewFinderMessages(
    Map<String, List<ChatModel>> previous,
    Map<String, List<ChatModel>> current,
  ) {
    final previousFingerprints = <String>{};
    for (final entry in previous.entries) {
      final session = entry.key;
      for (final msg in entry.value) {
        previousFingerprints.add(_fingerprint(session, msg));
      }
    }

    var count = 0;
    for (final entry in current.entries) {
      final session = entry.key;
      for (final msg in entry.value) {
        final key = _fingerprint(session, msg);
        if (previousFingerprints.contains(key)) {
          continue;
        }
        if (msg.senderType.toLowerCase() == 'finder') {
          count++;
        }
      }
    }

    return count;
  }

  String _fingerprint(String sessionId, ChatModel msg) {
    final id = msg.id;
    if (id.isNotEmpty) {
      return '$sessionId|$id';
    }
    return '$sessionId|${msg.senderType}|${msg.createdAt ?? ''}|${msg.message}';
  }

  void _jumpToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
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
      appBar: AppBar(
        title: Text('Chat Anonim - ${widget.assetName}'),
      ),
      backgroundColor: AppColors.bgBlue,
      body: Column(
        children: [
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (sessions.isEmpty)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.chat_bubble_outline,
                          size: 72, color: Colors.blueGrey),
                      SizedBox(height: 12),
                      Text(
                        'Belum ada chat anonim untuk QR ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sessionId = sessions[index];
                  final selected = sessionId == _selectedSessionId;
                  return ChoiceChip(
                    selected: selected,
                    label: Text('Sesi ${index + 1}'),
                    onSelected: (_) {
                      setState(() => _selectedSessionId = sessionId);
                      _jumpToBottom();
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadChats,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isOwner = msg.senderType.toLowerCase() == 'owner';
                    return Align(
                      alignment: isOwner
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          color: isOwner
                              ? AppColors.primaryBlue.withOpacity(0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOwner
                                ? AppColors.primaryBlue.withOpacity(0.3)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOwner ? 'Anda' : 'Finder',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isOwner
                                    ? AppColors.primaryBlue
                                    : Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(msg.message),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Balas ke finder...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Kirim'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
