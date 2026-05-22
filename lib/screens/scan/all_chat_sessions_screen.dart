import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/chat_model.dart';
import '../../models/qrcode_model.dart';
import '../../services/qrcode_service.dart';
import 'owner_chat_screen.dart';

const _kRed = Color(0xFFD32F2F);
const _kRedLight = Color(0xFFFFEBEE);
const _kBg = Color(0xFFF5F5F5);
const _kTextPrimary = Color(0xFF1A1A1A);
const _kTextSecondary = Color(0xFF757575);
const _kSuccess = Color(0xFF2E7D32);

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
          if (chats.isEmpty) return;
          final sorted = [...chats]..sort((a, b) =>
              (a.createdAt ?? '').compareTo(b.createdAt ?? ''));
          sessions.add(_SessionItem(
            assetId: asset.routeAssetId,
            assetName: asset.name,
            sessionId: sessionId,
            messages: sorted,
          ));
        });
      }
      sessions.sort((a, b) =>
          (b.lastMessage.createdAt ?? '').compareTo(a.lastMessage.createdAt ?? ''));
      if (!mounted) return;
      setState(() => _sessions = sessions);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Gagal memuat semua sesi chat.',
            style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<QrCodeModel>> _loadAllUserAssets(QrCodeService service) async {
    final result = <QrCodeModel>[];
    var page = 1;
    while (true) {
      final response = await service.getUserQrCodes(page: page, perPage: 50);
      result.addAll(response.items);
      if (!response.hasMore || page >= response.lastPage) break;
      page++;
    }
    return result;
  }

  Future<void> _confirmDeleteSession(_SessionItem session) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                      color: _kRedLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: _kRed, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Hapus Sesi Chat',
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kTextPrimary)),
              ]),
              const SizedBox(height: 14),
              Text(
                'Yakin hapus sesi "${session.assetName}"?',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: _kTextSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: _kBg,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text('Batal',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: _kTextSecondary))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                          color: _kRed,
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text('Hapus',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (ok != true || !mounted) return;

    final service = context.read<QrCodeService>();
    final deleted = await service.deleteAssetChatSession(
      assetId: session.assetId,
      sessionId: session.sessionId,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          deleted
              ? 'Sesi chat berhasil dihapus.'
              : 'Gagal hapus sesi chat.',
          style: GoogleFonts.poppins(fontSize: 13)),
      backgroundColor: deleted ? _kSuccess : _kRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));

    if (deleted) {
      setState(() {
        _sessions = _sessions
            .where((i) => !(i.assetId == session.assetId &&
                i.sessionId == session.sessionId))
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllSessions,
              color: _kRed,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kRed))
                  : _sessions.isEmpty
                      ? _buildEmpty()
                      : _buildList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16, right: 16, bottom: 14,
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
          child: const Icon(Icons.forum_rounded, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Semua Sesi Chat',
                  style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _kTextPrimary)),
              Text('${_sessions.length} sesi aktif',
                  style: GoogleFonts.poppins(
                      fontSize: 10, color: _kTextSecondary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: _loading ? null : _loadAllSessions,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _kRedLight,
                borderRadius: BorderRadius.circular(10)),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(9),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kRed))
                : const Icon(Icons.refresh_rounded, size: 18, color: _kRed),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return ListView(children: [
      const SizedBox(height: 80),
      Center(
        child: Column(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: _kRedLight,
                borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.forum_rounded, size: 36, color: _kRed),
          ),
          const SizedBox(height: 16),
          Text('Belum ada sesi chat anonim.',
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _kTextPrimary)),
          const SizedBox(height: 6),
          Text('Sesi muncul saat ada yang scan QR kamu.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _kTextSecondary)),
        ]),
      ),
    ]);
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final finderCount = session.messages
            .where((m) => m.senderType.toLowerCase() == 'finder')
            .length;
        final lastMsg = session.lastMessage;
        final isFinderLast = lastMsg.senderType.toLowerCase() == 'finder';

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => OwnerChatScreen(
                assetId: session.assetId,
                assetName: session.assetName,
                initialSessionId: session.sessionId,
              ),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB71C1C), _kRed],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      session.assetName.isNotEmpty
                          ? session.assetName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  ),
                ),
                if (finderCount > 0)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      width: 18, height: 18,
                      decoration: const BoxDecoration(
                          color: _kRed, shape: BoxShape.circle),
                      child: Center(
                        child: Text('$finderCount',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(session.assetName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kTextPrimary)),
                    const SizedBox(height: 3),
                    Row(children: [
                      if (isFinderLast)
                        Container(
                          margin: const EdgeInsets.only(right: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                              color: _kRedLight,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('Finder',
                              style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  color: _kRed,
                                  fontWeight: FontWeight.w700)),
                        ),
                      Expanded(
                        child: Text(lastMsg.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _kTextSecondary)),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _confirmDeleteSession(session),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                      color: _kRedLight,
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: _kRed),
                ),
              ),
            ]),
          ),
        );
      },
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
