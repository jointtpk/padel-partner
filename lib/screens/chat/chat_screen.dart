import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/tokens.dart';
import '../../core/mock_data.dart';
import '../../app/controllers/app_controller.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────
// Arguments: Map with keys:
//   'type'    → 'game' | 'friend'
//   'gameId'  → String (when type == 'game')
//   'userId'  → String (when type == 'friend')
//   'title'   → String (display name)

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final AppController _store;
  late final Map<String, dynamic> _args;
  late final String _type;
  late final String _id;
  late final String _title;

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _store = AppController.to;
    _args  = Get.arguments as Map<String, dynamic>;
    _type  = _args['type'] as String? ?? 'game';
    _id    = (_args['gameId'] ?? _args['userId'] ?? '') as String;
    _title = _args['title'] as String? ?? '';
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  List<dynamic> get _messages => _type == 'game'
      ? (_store.gameChats[_id] ?? [])
      : (_store.friendChats[_id] ?? []);

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.selectionClick();
    if (_type == 'game') {
      _store.sendGameMessage(_id, text);
    } else {
      _store.sendFriendMessage(_id, text);
    }
    _inputCtrl.clear();
    // Scroll to bottom after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Column(
        children: [
          _ChatHeader(title: _title, type: _type, id: _id, store: _store),
          Expanded(child: _MessageList(store: _store, type: _type, id: _id, scrollCtrl: _scrollCtrl)),
          _InputBar(ctrl: _inputCtrl, focus: _inputFocus, onSend: _send, bottom: bottom),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.title, required this.type, required this.id, required this.store});
  final String title;
  final String type;
  final String id;
  final AppController store;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      color: AppColors.blue900,
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar / icon
          type == 'friend'
              ? _FriendMiniAvatar(uid: id)
              : Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.blue800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('🎾', style: TextStyle(fontSize: 18))),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppFonts.body(15, color: Colors.white, weight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                Obx(() {
                  final count = type == 'game'
                      ? (store.gameChats[id] ?? []).length
                      : (store.friendChats[id] ?? []).length;
                  return Text(
                    type == 'game' ? '$count messages' : 'Direct message',
                    style: AppFonts.body(11, color: Colors.white.withOpacity(0.50)),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendMiniAvatar extends StatelessWidget {
  const _FriendMiniAvatar({required this.uid});
  final String uid;

  @override
  Widget build(BuildContext context) {
    final p = playerById(uid);
    if (p == null) {
      return Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: AppColors.mist, shape: BoxShape.circle),
      );
    }
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: p.avatarColor, shape: BoxShape.circle),
      child: Center(child: Text(p.initials, style: AppFonts.display(13, color: AppColors.ink))),
    );
  }
}

// ─── Message list ─────────────────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({required this.store, required this.type, required this.id, required this.scrollCtrl});
  final AppController store;
  final String type;
  final String id;
  final ScrollController scrollCtrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final messages = type == 'game'
          ? (store.gameChats[id] ?? [])
          : (store.friendChats[id] ?? []);

      if (messages.isEmpty) {
        return _EmptyChat(type: type);
      }

      return ListView.builder(
        controller: scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        itemCount: messages.length,
        itemBuilder: (_, i) {
          final msg = messages[i];
          final isMe = msg.from == 'me';
          final prev = i > 0 ? messages[i - 1] : null;
          final showSender = !isMe && (prev == null || prev.from != msg.from);

          return _MessageBubble(
            from: msg.from,
            text: msg.text,
            time: msg.t,
            isMe: isMe,
            showSender: showSender,
          );
        },
      );
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.from,
    required this.text,
    required this.time,
    required this.isMe,
    required this.showSender,
  });

  final String from;
  final String text;
  final String time;
  final bool isMe;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final player = isMe ? null : playerById(from);

    return Padding(
      padding: EdgeInsets.only(
        top: showSender ? 12 : 3,
        bottom: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // Sender mini avatar
            SizedBox(
              width: 28,
              child: showSender
                  ? Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: player?.avatarColor ?? AppColors.mist,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          player?.initials ?? '?',
                          style: AppFonts.display(10, color: AppColors.ink),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showSender && !isMe && player != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 3),
                    child: Text(
                      player.name.split(' ').first,
                      style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.40), letterSpacing: 0.3),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.ink : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    text,
                    style: AppFonts.body(14, color: isMe ? Colors.white : AppColors.ink, height: 1.35),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
                  child: Text(
                    time,
                    style: AppFonts.mono(9, color: AppColors.ink.withOpacity(0.30)),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 34),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.type});
  final String type;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type == 'game' ? '🎾' : '👋', style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 14),
            Text(
              type == 'game' ? 'Team chat is open' : 'Say hello!',
              style: AppFonts.display(18, color: AppColors.ink, letterSpacing: -0.3),
            ),
            const SizedBox(height: 6),
            Text(
              type == 'game'
                  ? 'Coordinate with your team before the game.'
                  : 'Start the conversation.',
              style: AppFonts.body(13, color: AppColors.ink.withOpacity(0.50), height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatefulWidget {
  const _InputBar({required this.ctrl, required this.focus, required this.onSend, required this.bottom});
  final TextEditingController ctrl;
  final FocusNode focus;
  final VoidCallback onSend;
  final double bottom;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(() {
      final has = widget.ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardH = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, (keyboardH > 0 ? 10 : widget.bottom + 10)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: widget.ctrl,
                focusNode: widget.focus,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: AppFonts.body(14, color: AppColors.ink),
                cursorColor: AppColors.blue800,
                decoration: InputDecoration(
                  hintText: 'Message…',
                  hintStyle: AppFonts.body(14, color: AppColors.ink.withOpacity(0.35)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _hasText ? AppColors.ink : AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: GestureDetector(
              onTap: _hasText ? widget.onSend : null,
              child: Icon(
                Icons.arrow_upward_rounded,
                color: _hasText ? AppColors.ball : AppColors.ink.withOpacity(0.25),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
