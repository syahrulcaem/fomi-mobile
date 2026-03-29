import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_theme.dart';
import '../../models/chat_model.dart';
import '../../models/qrcode_model.dart';
import '../../services/qrcode_service.dart';
import 'owner_chat_screen.dart';

class AllChatSessionsScreen extends StatefulWidget {
  const AllChatSessionsScreen({super.key});

  @override
  State<AllChatSessionsScreen> createState() => _AllChatSessionsScreenState();
}

class _AllChatSessionsScreenState extends State<AllChatSessionsScreen> {
  bool _loading = false;
  List<_SessionItem> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _loadAllSessions();
  }

  Future<void> _loadAllSessions() async {
    setState(() => _loading = true);

    try {
      final service = context.read<QrCodeService>();
      final assets = await _loadAllUserAssets(service);

      final sessions = <_SessionItem>[];
      for (final asset in assets) {
        final grouped = await service.getAssetChats(asset.routeAssetId);
        grouped.forEach((sessionId, chats) {
          if (chats.isEmpty) {
            return;
          }
          final sorted = [...chats]..sort((a, b) {
              final ta = a.createdAt ?? '';
              final tb = b.createdAt ?? '';
              return ta.compareTo(tb);
            });
          sessions.add(
            _SessionItem(
              assetId: asset.routeAssetId,
              assetName: asset.name,
              sessionId: sessionId,
              messages: sorted,
            ),
          );
        });
      }

      sessions.sort((a, b) {
        final aTime = a.lastMessage.createdAt ?? '';
        final bTime = b.lastMessage.createdAt ?? '';
        return bTime.compareTo(aTime);
      });

      if (!mounted) {
        return;
      }
      setState(() => _sessions = sessions);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat semua sesi chat.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<List<QrCodeModel>> _loadAllUserAssets(QrCodeService service) async {
    final result = <QrCodeModel>[];
    var page = 1;

    while (true) {
      final response = await service.getUserQrCodes(page: page, perPage: 50);
      result.addAll(response.items);

      if (!response.hasMore || page >= response.lastPage) {
        break;
      }
      page++;
    }

    return result;
  }

  Future<void> _confirmDeleteSession(_SessionItem session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus sesi chat'),
          content: Text(
            'Yakin hapus sesi ${session.sessionId} untuk ${session.assetName}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) {
      return;
    }

    final service = context.read<QrCodeService>();
    final deleted = await service.deleteAssetChatSession(
      assetId: session.assetId,
      sessionId: session.sessionId,
    );

    if (!mounted) {
      return;
    }

    if (!deleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Gagal hapus sesi chat. Endpoint delete belum tersedia.'),
        ),
      );
      return;
    }

    setState(() {
      _sessions = _sessions
          .where(
            (item) => !(item.assetId == session.assetId &&
                item.sessionId == session.sessionId),
          )
          .toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesi chat berhasil dihapus.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Sesi Chat'),
      ),
      backgroundColor: AppColors.bgBlue,
      body: RefreshIndicator(
        onRefresh: _loadAllSessions,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _sessions.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Icon(Icons.forum_outlined,
                          size: 72, color: Colors.blueGrey),
                      SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Belum ada sesi chat anonim.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      final finderCount = session.messages
                          .where((m) => m.senderType.toLowerCase() == 'finder')
                          .length;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          title: Text(
                            session.assetName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Sesi: ${session.sessionId}\n${session.lastMessage.message}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.softBlue,
                            child: Text(
                              finderCount.toString(),
                              style: const TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: 'Buka chat',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => OwnerChatScreen(
                                        assetId: session.assetId,
                                        assetName: session.assetName,
                                        initialSessionId: session.sessionId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.open_in_new),
                              ),
                              IconButton(
                                tooltip: 'Hapus sesi',
                                onPressed: () => _confirmDeleteSession(session),
                                icon: const Icon(Icons.delete_outline,
                                    color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _SessionItem {
  _SessionItem({
    required this.assetId,
    required this.assetName,
    required this.sessionId,
    required this.messages,
  });

  final String assetId;
  final String assetName;
  final String sessionId;
  final List<ChatModel> messages;

  ChatModel get lastMessage => messages.last;
}
