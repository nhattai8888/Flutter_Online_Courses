import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/api.dart';
import '../data/repository_impl.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';
import 'controller.dart';

class LessonScreen extends StatefulWidget {
  final LessonController? controller;
  final String lessonId;

  const LessonScreen({
    super.key,
    this.controller,
    required this.lessonId,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> with TickerProviderStateMixin {
  late final LessonController controller;

  // Duolingo-ish purple
  static const Color _purple = Color(0xFF6D28D9);
  static const Color _purple2 = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();

    final repo = LessonRepositoryImpl(LessonApi());
    controller = widget.controller ??
        LessonController(
          listItemsByLesson: ListItemsByLessonUseCase(repo),
          startAttempt: StartLessonAttemptUseCase(repo),
          submitAttempt: SubmitLessonAttemptUseCase(repo),
          getAttempt: GetAttemptUseCase(repo),
        );

    controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.init(widget.lessonId));
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final err = controller.error;
    if (err != null && err.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_purple, _purple2],
                ),
              ),
            ),
          ),
          const Positioned(top: -90, left: -70, child: _Blob(size: 240, color: Colors.white24)),
          const Positioned(bottom: -110, right: -80, child: _Blob(size: 300, color: Colors.white12)),
          SafeArea(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                return Column(
                  children: [
                    _TopBar(
                      title: controller.activeType == null ? 'Lesson' : controller.activeType!,
                      onBack: () => context.go('/curriculum'),
                      onReload: controller.phase == LessonUiPhase.loading ? null : controller.loadPreview,
                      showBackToPreview: controller.activeType != null,
                      onBackToPreview: controller.backToPreview,
                    ),
                    Expanded(
                      child: _Body(controller: controller),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final LessonController controller;

  const _Body({required this.controller});

  @override
  Widget build(BuildContext context) {
    final phase = controller.phase;

    if (phase == LessonUiPhase.loading) {
      return const Center(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }

    if (phase == LessonUiPhase.completed) {
      return _CompletedView(controller: controller);
    }

    if (phase == LessonUiPhase.practicing) {
      return _PracticeView(controller: controller);
    }

    // preview / error fall back to preview list
    return _PreviewView(controller: controller);
  }
}

/* =========================
   TOP BAR
========================= */

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onReload;

  final bool showBackToPreview;
  final VoidCallback onBackToPreview;

  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onReload,
    required this.showBackToPreview,
    required this.onBackToPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Back to Curriculum',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          if (showBackToPreview)
            IconButton(
              onPressed: onBackToPreview,
              icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
              tooltip: 'Lesson skills',
            )
          else
            const SizedBox(width: 40),
          IconButton(
            onPressed: onReload,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reload',
          ),
        ],
      ),
    );
  }
}

/* =========================
   PREVIEW (GROUP BY item_type)
========================= */

class _PreviewView extends StatelessWidget {
  final LessonController controller;

  const _PreviewView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final grouped = controller.groupPreviewByType();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          children: [
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.route_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chọn dạng bài để bắt đầu',
                        style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w900),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withOpacity(0.22)),
                      ),
                      child: Text(
                        '${controller.previewItems.length} items',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (controller.previewItems.isEmpty)
              const _SoftInfo(text: 'Lesson chưa có items.'),
            for (final entry in grouped.entries) ...[
              _SkillTile(
                type: entry.key,
                count: entry.value.length,
                onTap: () => controller.startType(entry.key),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final String type;
  final int count;
  final VoidCallback onTap;

  const _SkillTile({
    required this.type,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcon(type);
    final accent = _typeAccent(type);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.16),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _typeLabel(type),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count câu • chạm để bắt đầu',
                  style: TextStyle(color: Colors.white.withOpacity(0.88), fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ]),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String t) {
    switch (t) {
      case 'MCQ':
        return 'Trắc nghiệm';
      case 'CLOZE':
        return 'Điền từ';
      case 'MATCH':
        return 'Ghép đôi';
      case 'REORDER':
        return 'Sắp xếp';
      case 'LISTEN':
        return 'Nghe';
      case 'SPEAK':
        return 'Nói';
      default:
        return t;
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'MCQ':
        return Icons.list_alt_rounded;
      case 'CLOZE':
        return Icons.edit_rounded;
      case 'MATCH':
        return Icons.compare_arrows_rounded;
      case 'REORDER':
        return Icons.swap_vert_rounded;
      case 'LISTEN':
        return Icons.headphones_rounded;
      case 'SPEAK':
        return Icons.mic_rounded;
      default:
        return Icons.quiz_rounded;
    }
  }

  Color _typeAccent(String t) {
    switch (t) {
      case 'SPEAK':
        return const Color(0xFFEF4444);
      case 'LISTEN':
        return const Color(0xFF10B981);
      case 'MCQ':
        return const Color(0xFF3B82F6);
      case 'CLOZE':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6D28D9);
    }
  }
}

/* =========================
   PRACTICE VIEW (Duolingo-ish)
========================= */

class _PracticeView extends StatelessWidget {
  final LessonController controller;

  const _PracticeView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final item = controller.currentItem;
    if (item == null) {
      return const Center(child: _SoftInfo(text: 'Không có item cho dạng này.'));
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            children: [
              _ProgressBar(
                value: (controller.activeIndex + 1) / (controller.totalActive == 0 ? 1 : controller.totalActive),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _QuestionCard(
                    key: ValueKey(item.id),
                    item: item,
                    controller: controller,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _BottomBar(controller: controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;

  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 10,
        backgroundColor: Colors.white.withOpacity(0.18),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final LessonItem item;
  final LessonController controller;

  const _QuestionCard({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final prompt = (item.prompt ?? '').trim().isEmpty ? '—' : item.prompt!.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prompt,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, height: 1.2),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _ItemBody(item: item, controller: controller),
          ),
        ],
      ),
    );
  }
}

class _ItemBody extends StatelessWidget {
  final LessonItem item;
  final LessonController controller;

  const _ItemBody({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    switch (item.itemType) {
      case 'MCQ':
      case 'LISTEN':
        return _McqBody(item: item, controller: controller);
      case 'CLOZE':
        return _ClozeBody(item: item, controller: controller);
      default:
        return _FallbackBody(item: item);
    }
  }
}

class _McqBody extends StatelessWidget {
  final LessonItem item;
  final LessonController controller;

  const _McqBody({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final current = controller.answers[item.id]?['answer'];

    if (item.choices.isEmpty) {
      return const _SoftInfo(text: 'Không có đáp án lựa chọn.');
    }

    return ListView(
      children: [
        for (final c in item.choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoicePill(
              selected: current == c.key,
              text: c.text,
              onTap: () => controller.setAnswer(item.id, c.key),
            ),
          ),
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final bool selected;
  final String text;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.selected,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected ? Colors.white : Colors.white.withOpacity(0.12),
          border: Border.all(color: Colors.white.withOpacity(selected ? 0.0 : 0.24)),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? const Color(0xFF111827) : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClozeBody extends StatelessWidget {
  final LessonItem item;
  final LessonController controller;

  const _ClozeBody({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final v = controller.answers[item.id]?['answer'];
    final text = v is String ? v : '';

    return TextField(
      controller: TextEditingController(text: text)
        ..selection = TextSelection.fromPosition(TextPosition(offset: text.length)),
      onChanged: (x) => controller.setAnswer(item.id, x.trim()),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      decoration: InputDecoration(
        hintText: 'Nhập câu trả lời…',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700),
        filled: true,
        fillColor: Colors.white.withOpacity(0.12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}

class _FallbackBody extends StatelessWidget {
  final LessonItem item;

  const _FallbackBody({required this.item});

  @override
  Widget build(BuildContext context) {
    return _SoftInfo(text: 'Item type "${item.itemType}" chưa có UI chi tiết.');
  }
}

class _BottomBar extends StatelessWidget {
  final LessonController controller;

  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final idx = controller.activeIndex + 1;
    final total = controller.totalActive;

    return Row(
      children: [
        _SmallBtn(
          icon: Icons.arrow_back_rounded,
          onTap: controller.activeIndex == 0 ? null : controller.prev,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _PrimaryBtn(
            label: controller.canCheck
                ? (idx == total ? 'HOÀN THÀNH' : 'TIẾP TỤC')
                : 'CHỌN ĐÁP ÁN',
            enabled: controller.canCheck,
            onTap: controller.canCheck ? controller.next : null,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.22)),
          ),
          child: Text(
            '$idx/$total',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  const _PrimaryBtn({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled ? Colors.white : Colors.white.withOpacity(0.14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: enabled ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.75),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _SmallBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: enabled ? Colors.white.withOpacity(0.16) : Colors.white.withOpacity(0.10),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Icon(icon, color: enabled ? Colors.white : Colors.white.withOpacity(0.55)),
      ),
    );
  }
}

/* =========================
   COMPLETED VIEW
========================= */

class _CompletedView extends StatelessWidget {
  final LessonController controller;

  const _CompletedView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final r = controller.result;

    final percent = r?.scorePercent ?? 0;
    final points = r?.scorePoints ?? 0;
    final max = r?.maxPoints ?? 0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 44),
                      const SizedBox(height: 10),
                      const Text(
                        'Hoàn thành!',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$percent%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 44),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$points/$max điểm',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 14),
                      _PrimaryBtn(
                        label: 'QUAY LẠI CURRICULUM',
                        enabled: true,
                        onTap: () => context.go('/curriculum?completed_lesson=${controller.lessonId ?? ''}'),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: controller.backToPreview,
                        child: Text(
                          'Chọn dạng bài khác',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
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
      ),
    );
  }
}

/* =========================
   SHARED UI
========================= */

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size / 2)),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: child,
      ),
    );
  }
}

class _SoftInfo extends StatelessWidget {
  final String text;
  const _SoftInfo({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.14),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
