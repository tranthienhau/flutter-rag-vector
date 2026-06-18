import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rag/vector_store.dart';
import 'chat_controller.dart';
import 'theme.dart';

/// InsightEngine - the research-assistant chat surface.
///
/// Empty state shows a brand mark, greeting and "bento" starter cards. Once a
/// conversation exists it renders user queries with topic chips and grounded
/// AI answer cards: inline citation badges, a Sources panel built from the
/// retrieved chunks, and answer action buttons.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  void _send([String? preset]) {
    final q = (preset ?? _input.text).trim();
    if (q.isEmpty) return;
    _input.clear();
    setState(() {});
    ref.read(chatControllerProvider.notifier).ask(q);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 240,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatControllerProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _TopBar(),
            Expanded(
              child: messages.isEmpty
                  ? _EmptyState(onStarter: _send)
                  : _Conversation(messages: messages, scroll: _scroll),
            ),
            _Composer(input: _input, onSend: () => _send()),
            const _BottomNav(),
          ],
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Top app bar
// --------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0x33C7C4D8)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.menu, color: AppColors.primary),
          const SizedBox(width: 12),
          const Text(
            'InsightEngine',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person,
                size: 20, color: AppColors.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Empty state
// --------------------------------------------------------------------------

class _Starter {
  const _Starter(this.icon, this.tint, this.iconColor, this.title, this.body);
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String body;
}

const _starters = [
  _Starter(Icons.description_outlined, AppColors.primaryFixed, AppColors.primary,
      'Summarize Documents',
      'Upload PDFs or research papers for instant executive summaries.'),
  _Starter(Icons.trending_up, AppColors.secondaryContainer,
      AppColors.onSecondaryContainer, 'Analyze Trends',
      'Extract pattern data and market shifts from historical datasets.'),
  _Starter(Icons.insights_outlined, AppColors.tertiaryFixed, AppColors.tertiary,
      'Strategic Planning',
      'Draft roadmap frameworks based on competitive analysis inputs.'),
];

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStarter});
  final void Function(String) onStarter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0x33C7C4D8)),
                boxShadow: kCardShadow,
              ),
              child: const Icon(Icons.rocket_launch,
                  size: 52, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 28),
          Text('How can I assist your\nresearch today?',
              textAlign: TextAlign.center, style: kHeadlineXl),
          const SizedBox(height: 14),
          Text(
            'InsightEngine leverages high-precision neural models to '
            'synthesize complex data into actionable strategic intelligence.',
            textAlign: TextAlign.center,
            style: kBodyLg,
          ),
          const SizedBox(height: 32),
          for (final s in _starters) ...[
            _StarterCard(starter: s, onTap: () => onStarter(s.title)),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.starter, required this.onTap});
  final _Starter starter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB3FFFFFF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEFF4FF)),
            boxShadow: kCardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: starter.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(starter.icon, color: starter.iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(starter.title,
                        style: kBodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Geist')),
                    const SizedBox(height: 4),
                    Text(starter.body, style: kBodySm),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Conversation
// --------------------------------------------------------------------------

class _Conversation extends StatelessWidget {
  const _Conversation({required this.messages, required this.scroll});
  final List<ChatMessage> messages;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        return m.role == 'user'
            ? _UserQuery(text: m.content)
            : _AnswerCard(message: m);
      },
    );
  }
}

class _UserQuery extends StatelessWidget {
  const _UserQuery({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x33C7C4D8)),
            ),
            child: const Icon(Icons.person,
                size: 18, color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: kHeadlineMd,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final composing = message.content.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(10),
              boxShadow: kCardShadow,
            ),
            child: const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEFF4FF)),
                boxShadow: kCardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (composing)
                    const _ThinkingIndicator()
                  else
                    _CitedText(content: message.content),
                  if (message.citations.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _Divider(),
                    const SizedBox(height: 16),
                    Text('SOURCES', style: kLabelSm),
                    const SizedBox(height: 12),
                    for (var i = 0; i < message.citations.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SourceChip(
                            index: i + 1, chunk: message.citations[i]),
                      ),
                  ],
                  if (!composing) ...[
                    const SizedBox(height: 14),
                    const _AnswerActions(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders assistant text, turning `[cite:N]` markers into inline badges.
class _CitedText extends StatelessWidget {
  const _CitedText({required this.content});
  final String content;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final re = RegExp(r'\[cite:(\d+)\]');
    var last = 0;
    for (final match in re.allMatches(content)) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start)));
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _CitationBadge(label: match.group(1)!),
        ),
      ));
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last)));
    }
    return Text.rich(TextSpan(style: kBodyMd, children: spans));
  }
}

class _CitationBadge extends StatelessWidget {
  const _CitationBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          )),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.index, required this.chunk});
  final int index;
  final RetrievedChunk chunk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x33C7C4D8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.menu_book,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chunk.chunk.sourceId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: kBodySm.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface)),
                const SizedBox(height: 2),
                Text(chunk.chunk.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: kLabelSm.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('[$index]',
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                )),
          ),
        ],
      ),
    );
  }
}

class _AnswerActions extends StatelessWidget {
  const _AnswerActions();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        _PillButton(icon: Icons.thumb_up_outlined, label: 'Helpful'),
        _PillButton(icon: Icons.content_copy, label: 'Copy'),
        _PillButton(icon: Icons.ios_share, label: 'Share', filled: true),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton(
      {required this.icon, required this.label, this.filled = false});
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryContainer : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 15,
              color: filled ? Colors.white : AppColors.onSurface),
          const SizedBox(width: 6),
          Text(label,
              style: kLabelMd.copyWith(
                  color: filled ? Colors.white : AppColors.onSurface)),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text('Retrieving sources...', style: kBodyMd),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: const Color(0x33C7C4D8));
}

// --------------------------------------------------------------------------
// Composer
// --------------------------------------------------------------------------

const _quickActions = [
  (Icons.picture_as_pdf_outlined, 'Add PDF'),
  (Icons.language, 'Web Search'),
  (Icons.auto_fix_high, 'Refine Prompt'),
  (Icons.data_exploration_outlined, 'Analyze Data'),
];

class _Composer extends StatelessWidget {
  const _Composer({required this.input, required this.onSend});
  final TextEditingController input;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: AppColors.surface,
      child: Column(
        children: [
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickActions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final (icon, label) = _quickActions[i];
                final primary = i == 0;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary
                        ? AppColors.primaryFixed
                        : AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          size: 16,
                          color: primary
                              ? AppColors.onPrimaryFixedVariant
                              : AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(label,
                          style: kLabelMd.copyWith(
                              color: primary
                                  ? AppColors.onPrimaryFixedVariant
                                  : AppColors.onSurfaceVariant)),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            decoration: BoxDecoration(
              color: const Color(0xE6FFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x66C7C4D8)),
              boxShadow: kCardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_file,
                      color: AppColors.onSurfaceVariant),
                ),
                Expanded(
                  child: TextField(
                    controller: input,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: kBodyMd,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                      border: InputBorder.none,
                      hintText: 'Message InsightEngine...',
                      hintStyle: kLabelMd.copyWith(color: AppColors.outline),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onSend,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------------------
// Bottom navigation
// --------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Color(0x33C7C4D8))),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: const [
          _NavItem(icon: Icons.chat_bubble, label: 'Chat', active: true),
          _NavItem(icon: Icons.explore_outlined, label: 'Explore'),
          _NavItem(icon: Icons.description_outlined, label: 'Docs'),
          _NavItem(icon: Icons.person_outline, label: 'Profile'),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon, required this.label, this.active = false});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 22,
            color:
                active ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant),
        const SizedBox(height: 2),
        Text(label,
            style: kLabelSm.copyWith(
                color: active
                    ? AppColors.onSecondaryContainer
                    : AppColors.onSurfaceVariant)),
      ],
    );
    if (!active) return content;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(999),
      ),
      child: content,
    );
  }
}
