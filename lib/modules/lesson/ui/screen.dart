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

class _LessonScreenState extends State<LessonScreen> {
  late final LessonController controller;

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
        );

    controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.init(widget.lessonId));
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final err = controller.error;
    if (err != null && err.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<bool> _confirmExitIfPracticing() async {
    if (controller.phase != LessonMvpPhase.practicing) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thoát bài học?'),
        content: const Text('Bạn đang làm dở. Thoát sẽ mất tiến trình của dạng bài hiện tại.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Ở lại')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Thoát')),
        ],
      ),
    );
    return ok ?? false;
  }

  void _goCurriculumCompleted() {
    context.go('/curriculum?completed_lesson=${widget.lessonId}');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final ok = await _confirmExitIfPracticing();
        if (!ok) return false;
        context.go('/curriculum');
        return false;
      },
      child: Scaffold(
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
                        title: controller.activeType?.apiValue ?? 'Lesson',
                        onBack: () async {
                          final ok = await _confirmExitIfPracticing();
                          if (!ok) return;
                          context.go('/curriculum');
                        },
                        onBackToPreview: controller.phase == LessonMvpPhase.practicing ? controller.backToPreview : null,
                        onReload: (controller.phase == LessonMvpPhase.loadingAttempt ||
                                controller.phase == LessonMvpPhase.loadingPreview ||
                                controller.phase == LessonMvpPhase.submitting)
                            ? null
                            : controller.loadPreview,
                      ),
                      Expanded(
                        child: _Body(
                          controller: controller,
                          onCompletedGoCurriculum: _goCurriculumCompleted,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final LessonController controller;
  final VoidCallback onCompletedGoCurriculum;

  const _Body({
    required this.controller,
    required this.onCompletedGoCurriculum,
  });

  @override
  Widget build(BuildContext context) {
    switch (controller.phase) {
      case LessonMvpPhase.loadingPreview:
      case LessonMvpPhase.loadingAttempt:
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        );

      case LessonMvpPhase.practicing:
        return _PracticeView(controller: controller);

      case LessonMvpPhase.completed:
        return _CompletedView(controller: controller, onGoCurriculum: onCompletedGoCurriculum);

      case LessonMvpPhase.submitting:
        // unused now (we do optimistic)
        return const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
          ),
        );

      case LessonMvpPhase.preview:
      case LessonMvpPhase.error:
      default:
        return _PreviewView(controller: controller);
    }
  }
}

/* =========================
   TOP BAR
========================= */

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback? onBackToPreview;
  final VoidCallback? onReload;

  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onBackToPreview,
    required this.onReload,
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
          if (onBackToPreview != null)
            IconButton(
              onPressed: onBackToPreview,
              icon: const Icon(Icons.grid_view_rounded, color: Colors.white),
              tooltip: 'Skills',
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
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
   PREVIEW (Duolingo skill tiles by item_type)
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
                        controller.hasAttempt ? 'Chọn dạng bài để tiếp tục' : 'Chọn dạng bài để bắt đầu',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                      ),
                    ),
                    _Pill(text: controller.hasAttempt ? 'Attempt started' : 'Ready'),
                  ],
                ),
              ),
            ),

            // ✅ THÊM NÚT Ở ĐÂY
            const SizedBox(height: 12),
            _VocabCTAButton(lessonId: controller.lessonId),
            const SizedBox(height: 14),

            if (grouped.isEmpty) const _SoftInfo(text: 'Lesson chưa có items.'),

            for (final entry in grouped.entries) ...[
              _SkillTile(
                type: entry.key,
                count: entry.value.length,
                isDone: controller.completedTypes.contains(entry.key),
                onTap: () => controller.startType(entry.key),
              ),
              const SizedBox(height: 12),
            ],

            // ... phần submit card giữ nguyên
          ],
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final LessonItemType type;
  final int count;
  final bool isDone;
  final VoidCallback onTap;

  const _SkillTile({
    required this.type,
    required this.count,
    required this.isDone,
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
                Row(
                  children: [
                    Text(
                      _typeLabel(type),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    if (isDone)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'DONE',
                          style: TextStyle(
                            color: Color(0xFF6D28D9),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$count câu • chạm để vào',
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

  String _typeLabel(LessonItemType t) {
    switch (t) {
      case LessonItemType.mcq:
        return 'Trắc nghiệm';
      case LessonItemType.cloze:
        return 'Điền từ';
      case LessonItemType.match:
        return 'Ghép đôi';
      case LessonItemType.reorder:
        return 'Sắp xếp';
      case LessonItemType.listen:
        return 'Nghe';
      case LessonItemType.speak:
        return 'Nói';
      case LessonItemType.dialogue:
        return 'Hội thoại';
      case LessonItemType.recorder:
        return 'Ghi âm';
      case LessonItemType.other:
        return 'Khác';
    }
  }

  IconData _typeIcon(LessonItemType t) {
    switch (t) {
      case LessonItemType.mcq:
        return Icons.list_alt_rounded;
      case LessonItemType.cloze:
        return Icons.edit_rounded;
      case LessonItemType.match:
        return Icons.compare_arrows_rounded;
      case LessonItemType.reorder:
        return Icons.swap_vert_rounded;
      case LessonItemType.listen:
        return Icons.headphones_rounded;
      case LessonItemType.speak:
        return Icons.mic_rounded;
      case LessonItemType.dialogue:
        return Icons.forum_rounded;
      case LessonItemType.recorder:
        return Icons.keyboard_voice_rounded;
      case LessonItemType.other:
        return Icons.quiz_rounded;
    }
  }

  Color _typeAccent(LessonItemType t) {
    switch (t) {
      case LessonItemType.speak:
      case LessonItemType.recorder:
        return const Color(0xFFEF4444);
      case LessonItemType.listen:
        return const Color(0xFF10B981);
      case LessonItemType.mcq:
        return const Color(0xFF3B82F6);
      case LessonItemType.cloze:
        return const Color(0xFFF59E0B);
      case LessonItemType.dialogue:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6D28D9);
    }
  }
}

/* =========================
   PRACTICE VIEW (CHECK/CONTINUE Duolingo-like)
========================= */

class _PracticeView extends StatelessWidget {
  final LessonController controller;

  const _PracticeView({required this.controller});

  @override
  Widget build(BuildContext context) {
    final item = controller.currentItem;
    if (item == null) return const Center(child: _SoftInfo(text: 'Không có item cho dạng này.'));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            children: [
              _ProgressBar(value: controller.activeProgress),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
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
              _BottomFeedbackBar(controller: controller, item: item),
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
      case LessonItemType.mcq:
      case LessonItemType.listen:
        return _McqBody(item: item, controller: controller);

      case LessonItemType.cloze:
        return _ClozeBody(item: item, controller: controller);

      case LessonItemType.match:
        return _MatchBody(item: item, controller: controller);

      case LessonItemType.reorder:
        return _ReorderBody(item: item, controller: controller);

      case LessonItemType.dialogue:
        return _DialogueBody(item: item, controller: controller);

      case LessonItemType.speak:
      case LessonItemType.recorder:
        return _SpeakRecorderBody(item: item, controller: controller);

      case LessonItemType.other:
        return _PlaceholderBody(item: item, controller: controller);
    }
  }
}

/* ========= MCQ/LISTEN ========= */

class _McqBody extends StatelessWidget {
  final LessonItem item;
  final LessonController controller;

  const _McqBody({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final current = controller.getAnswerEntry(item.id)?['answer'];

    if (item.choices.isEmpty) return const _SoftInfo(text: 'Không có lựa chọn.');

    return ListView(
      children: [
        for (final c in item.choices)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChoicePill(
              selected: current == c.key,
              text: c.text,
              locked: controller.checkState == CheckState.checked,
              onTap: () {
                if (controller.checkState == CheckState.checked) return;
                controller.setAnswer(item.id, c.key);
              },
            ),
          ),
        if (item.itemType == LessonItemType.listen) ...[
          const SizedBox(height: 8),
          _HintCard(
            icon: Icons.volume_up_rounded,
            text: 'LISTEN: nếu content có audio_url, bạn có thể hiển thị/nhúng player ở bước sau. MVP giữ tối giản.',
          ),
        ],
      ],
    );
  }
}

class _ChoicePill extends StatelessWidget {
  final bool selected;
  final String text;
  final bool locked;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.selected,
    required this.text,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: locked ? null : onTap,
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

/* ========= CLOZE ========= */

class _ClozeBody extends StatefulWidget {
  final LessonItem item;
  final LessonController controller;

  const _ClozeBody({required this.item, required this.controller});

  @override
  State<_ClozeBody> createState() => _ClozeBodyState();
}

class _ClozeBodyState extends State<_ClozeBody> {
  late final TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    final v = widget.controller.getAnswerEntry(widget.item.id)?['answer'];
    _tc = TextEditingController(text: v is String ? v : '');
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.controller.checkState == CheckState.checked;

    return TextField(
      controller: _tc,
      enabled: !locked,
      onChanged: (x) => widget.controller.setAnswer(widget.item.id, x.trim()),
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

/* ========= MATCH (tap-to-match pairs) =========
Expected content shape (flexible):
content: {
  "left": [{"id":"a","text":"..."}, ...] or ["..."]
  "right": [{"id":"1","text":"..."}, ...] or ["..."]
}
Answer shape:
answer: {"pairs": [{"left":"a","right":"1"}, ...]}
meta: {"mode":"tap-match"}
*/

class _MatchBody extends StatefulWidget {
  final LessonItem item;
  final LessonController controller;

  const _MatchBody({required this.item, required this.controller});

  @override
  State<_MatchBody> createState() => _MatchBodyState();
}

class _MatchBodyState extends State<_MatchBody> {
  String? _selectedLeftId;
  final Map<String, String> _pairs = {}; // leftId -> rightId

  List<_Opt> _parseSide(String key) {
    final c = widget.item.content ?? const <String, dynamic>{};
    final raw = c[key];
    final out = <_Opt>[];

    if (raw is List) {
      for (final x in raw) {
        if (x is Map) {
          final m = x.cast<String, dynamic>();
          out.add(_Opt(id: (m['id'] ?? m['key'] ?? '').toString(), text: (m['text'] ?? m['label'] ?? '').toString()));
        } else {
          out.add(_Opt(id: x.toString(), text: x.toString()));
        }
      }
    }
    return out;
  }

  @override
  void initState() {
    super.initState();
    final prev = widget.controller.getAnswerEntry(widget.item.id)?['answer'];
    if (prev is Map && prev['pairs'] is List) {
      for (final p in (prev['pairs'] as List)) {
        if (p is Map) {
          final m = p.cast<String, dynamic>();
          final l = (m['left'] ?? '').toString();
          final r = (m['right'] ?? '').toString();
          if (l.isNotEmpty && r.isNotEmpty) _pairs[l] = r;
        }
      }
    }
  }

  void _emit() {
    final pairs = <Map<String, String>>[];
    for (final e in _pairs.entries) {
      pairs.add({'left': e.key, 'right': e.value});
    }
    widget.controller.setAnswer(
      widget.item.id,
      {'pairs': pairs},
      meta: {'mode': 'tap-match'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.controller.checkState == CheckState.checked;

    final left = _parseSide('left');
    final right = _parseSide('right');

    if (left.isEmpty || right.isEmpty) {
      return const _SoftInfo(text: 'MATCH: thiếu content.left/content.right');
    }

    return Column(
      children: [
        _HintCard(icon: Icons.touch_app_rounded, text: 'Chạm 1 ô bên trái → chạm 1 ô bên phải để ghép.'),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (final o in left)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MatchTile(
                          label: o.text,
                          selected: _selectedLeftId == o.id,
                          disabled: locked,
                          done: _pairs.containsKey(o.id),
                          onTap: () {
                            if (locked) return;
                            setState(() => _selectedLeftId = o.id);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ListView(
                  children: [
                    for (final o in right)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MatchTile(
                          label: o.text,
                          selected: false,
                          disabled: locked,
                          done: _pairs.containsValue(o.id),
                          onTap: () {
                            if (locked) return;
                            final l = _selectedLeftId;
                            if (l == null) return;

                            setState(() {
                              // ensure each right used once (simple)
                              _pairs.removeWhere((_, v) => v == o.id);
                              _pairs[l] = o.id;
                              _selectedLeftId = null;
                            });
                            _emit();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _MiniMetaRow(
          left: 'Đã ghép: ${_pairs.length}/${left.length}',
          right: locked
              ? 'Locked'
              : TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedLeftId = null;
                      _pairs.clear();
                    });
                    _emit();
                  },
                  child: const Text('Reset'),
                ),
        ),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool done;
  final bool disabled;
  final VoidCallback onTap;

  const _MatchTile({
    required this.label,
    required this.selected,
    required this.done,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = selected
        ? Colors.white
        : done
            ? Colors.white.withOpacity(0.22)
            : Colors.white.withOpacity(0.12);

    final Color fg = selected ? const Color(0xFF111827) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: disabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bg,
          border: Border.all(color: Colors.white.withOpacity(selected ? 0 : 0.24)),
        ),
        child: Row(
          children: [
            Icon(done ? Icons.link_rounded : Icons.circle_outlined, color: fg.withOpacity(0.95), size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
  }
}

/* ========= REORDER =========
Expected content shape:
content: { "tokens": ["I","am","fine"] } or { "items":[...] }
Answer: {"order":[...]} meta: {"mode":"reorder"}
*/

class _ReorderBody extends StatefulWidget {
  final LessonItem item;
  final LessonController controller;

  const _ReorderBody({required this.item, required this.controller});

  @override
  State<_ReorderBody> createState() => _ReorderBodyState();
}

class _ReorderBodyState extends State<_ReorderBody> {
  late List<String> _tokens;

  List<String> _parseTokens() {
    final c = widget.item.content ?? const <String, dynamic>{};
    final raw = c['tokens'] ?? c['items'] ?? c['words'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return <String>[];
  }

  @override
  void initState() {
    super.initState();
    final prev = widget.controller.getAnswerEntry(widget.item.id)?['answer'];
    if (prev is Map && prev['order'] is List) {
      _tokens = (prev['order'] as List).map((e) => e.toString()).toList();
    } else {
      _tokens = _parseTokens();
    }
  }

  void _emit() {
    widget.controller.setAnswer(
      widget.item.id,
      {'order': List<String>.from(_tokens)},
      meta: {'mode': 'reorder'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.controller.checkState == CheckState.checked;
    if (_tokens.isEmpty) return const _SoftInfo(text: 'REORDER: thiếu content.tokens');

    return Column(
      children: [
        _HintCard(icon: Icons.drag_indicator_rounded, text: 'Kéo để sắp xếp đúng thứ tự.'),
        const SizedBox(height: 10),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _tokens.length,
            onReorder: locked
                ? (_, __) {}
                : (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _tokens.removeAt(oldIndex);
                      _tokens.insert(newIndex, item);
                    });
                    _emit();
                  },
            itemBuilder: (ctx, i) {
              final t = _tokens[i];
              return Container(
                key: ValueKey('tok_$i$t'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.24)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.drag_indicator_rounded, color: Colors.white.withOpacity(0.85)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _MiniMetaRow(
          left: 'Số từ: ${_tokens.length}',
          right: locked
              ? 'Locked'
              : TextButton(
                  onPressed: () {
                    setState(() => _tokens = _parseTokens());
                    _emit();
                  },
                  child: const Text('Reset'),
                ),
        ),
      ],
    );
  }
}

/* ========= DIALOGUE =========
Render dialogue lines from content:
content: { "lines":[{"speaker":"A","text":"..."}, ...] }
Answer: e.g. { "read": true } meta: { "mode":"dialogue-read" }
MVP: mark read + allow continue.
*/

class _DialogueBody extends StatelessWidget {
  final LessonItem item;
  final LessonController controller;

  const _DialogueBody({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final locked = controller.checkState == CheckState.checked;
    final c = item.content ?? const <String, dynamic>{};
    final rawLines = c['lines'];

    final lines = <Map<String, String>>[];
    if (rawLines is List) {
      for (final x in rawLines) {
        if (x is Map) {
          final m = x.cast<String, dynamic>();
          lines.add({
            'speaker': (m['speaker'] ?? '').toString(),
            'text': (m['text'] ?? '').toString(),
          });
        }
      }
    }

    if (lines.isEmpty) {
      return const _SoftInfo(text: 'DIALOGUE: thiếu content.lines');
    }

    final already = controller.getAnswerEntry(item.id)?['answer'];
    final read = (already is Map && already['read'] == true);

    return Column(
      children: [
        _HintCard(icon: Icons.forum_rounded, text: 'Đọc hội thoại. MVP: đánh dấu đã đọc để CHECK.'),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            children: [
              for (final l in lines) ...[
                _Bubble(
                  speaker: l['speaker'] ?? '',
                  text: l['text'] ?? '',
                  isLeft: (l['speaker'] ?? '').toUpperCase() != 'YOU',
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: locked
              ? null
              : () {
                  controller.setAnswer(item.id, {'read': true}, meta: {'mode': 'dialogue-read'});
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: read ? Colors.white : Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(read ? 0 : 0.24)),
            ),
            child: Row(
              children: [
                Icon(read ? Icons.check_circle_rounded : Icons.done_rounded,
                    color: read ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.9)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    read ? 'Đã đọc xong' : 'Đánh dấu đã đọc',
                    style: TextStyle(
                      color: read ? const Color(0xFF111827) : Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String speaker;
  final String text;
  final bool isLeft;

  const _Bubble({
    required this.speaker,
    required this.text,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isLeft ? Colors.white.withOpacity(0.18) : Colors.white;
    final fg = isLeft ? Colors.white : const Color(0xFF111827);

    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (speaker.trim().isNotEmpty)
              Text(speaker, style: TextStyle(color: fg.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 12)),
            if (speaker.trim().isNotEmpty) const SizedBox(height: 6),
            Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.w800, height: 1.25)),
          ],
        ),
      ),
    );
  }
}

/* ========= SPEAK / RECORDER =========
No extra deps. We support 2 production-safe ways:
- User pastes media_id OR audio_url (from Media module flow elsewhere)
- Provide duration_ms + audio_mime
Answer:
{ "media_id": "...", "audio_url": "...", "audio_mime": "audio/wav", "duration_ms": 1234 }
meta: { "mode":"speak"|"recorder", "source":"uploaded" }
*/

class _SpeakRecorderBody extends StatefulWidget {
  final LessonItem item;
  final LessonController controller;

  const _SpeakRecorderBody({required this.item, required this.controller});

  @override
  State<_SpeakRecorderBody> createState() => _SpeakRecorderBodyState();
}

class _SpeakRecorderBodyState extends State<_SpeakRecorderBody> {
  final _mediaId = TextEditingController();
  final _audioUrl = TextEditingController();
  final _durationMs = TextEditingController(text: '0');
  String _mime = 'audio/wav';

  @override
  void initState() {
    super.initState();
    final prev = widget.controller.getAnswerEntry(widget.item.id)?['answer'];
    if (prev is Map) {
      _mediaId.text = (prev['media_id'] ?? '').toString();
      _audioUrl.text = (prev['audio_url'] ?? '').toString();
      _durationMs.text = (prev['duration_ms'] ?? 0).toString();
      _mime = (prev['audio_mime'] ?? 'audio/wav').toString();
    }
  }

  @override
  void dispose() {
    _mediaId.dispose();
    _audioUrl.dispose();
    _durationMs.dispose();
    super.dispose();
  }

  void _emit() {
    final dur = int.tryParse(_durationMs.text.trim()) ?? 0;
    widget.controller.setAnswer(
      widget.item.id,
      {
        'media_id': _mediaId.text.trim().isEmpty ? null : _mediaId.text.trim(),
        'audio_url': _audioUrl.text.trim().isEmpty ? null : _audioUrl.text.trim(),
        'audio_mime': _mime,
        'duration_ms': dur,
      },
      meta: {
        'mode': widget.item.itemType == LessonItemType.speak ? 'speak' : 'recorder',
        'source': 'uploaded',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.controller.checkState == CheckState.checked;

    return Column(
      children: [
        _HintCard(
          icon: Icons.mic_rounded,
          text:
              'MVP Product: không thêm plugin thu âm. Hãy upload audio qua Media flow, rồi dán media_id hoặc audio_url vào đây.',
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _mediaId,
          enabled: !locked,
          onChanged: (_) => _emit(),
          decoration: _fieldDeco('media_id (khuyến nghị)', Icons.cloud_upload_rounded),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _audioUrl,
          enabled: !locked,
          onChanged: (_) => _emit(),
          decoration: _fieldDeco('audio_url (nếu có)', Icons.link_rounded),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _durationMs,
                enabled: !locked,
                keyboardType: TextInputType.number,
                onChanged: (_) => _emit(),
                decoration: _fieldDeco('duration_ms', Icons.timer_rounded),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _mime,
                items: const [
                  DropdownMenuItem(value: 'audio/wav', child: Text('audio/wav')),
                  DropdownMenuItem(value: 'audio/mpeg', child: Text('audio/mpeg')),
                  DropdownMenuItem(value: 'audio/mp4', child: Text('audio/mp4')),
                ],
                onChanged: locked
                    ? null
                    : (v) {
                        setState(() => _mime = v ?? 'audio/wav');
                        _emit();
                      },
                decoration: _fieldDeco('audio_mime', Icons.music_note_rounded),
                dropdownColor: const Color(0xFF2B164A),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _SoftInfo(
          text: 'Tip: chỉ cần 1 trong 2 (media_id hoặc audio_url). Nếu để trống, hãy dùng “Skip”.',
        ),
        const SizedBox(height: 10),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: locked ? null : () => widget.controller.markItemSkipped(widget.item.id, reason: 'no-audio'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.24)),
            ),
            child: Row(
              children: [
                Icon(Icons.fast_forward_rounded, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Skip (no audio yet)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDeco(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700),
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    );
  }
}

/* ========= OTHER PLACEHOLDER ========= */

class _PlaceholderBody extends StatelessWidget {
  final LessonItem item;
  final LessonController controller;

  const _PlaceholderBody({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    final type = item.itemType.apiValue;
    final locked = controller.checkState == CheckState.checked;

    return Column(
      children: [
        _SoftInfo(text: 'UI chi tiết cho "$type" chưa có.'),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: locked ? null : () => controller.markItemSkipped(item.id, reason: 'placeholder'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.24)),
            ),
            child: Row(
              children: [
                Icon(Icons.fast_forward_rounded, color: Colors.white.withOpacity(0.9)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* =========================
   Bottom feedback bar (CHECK/CONTINUE)
========================= */

class _BottomFeedbackBar extends StatelessWidget {
  final LessonController controller;
  final LessonItem item;

  const _BottomFeedbackBar({
    required this.controller,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final isChecked = controller.checkState == CheckState.checked;

    final panelColor = isChecked ? Colors.white : Colors.white.withOpacity(0.14);
    final textColor = isChecked ? const Color(0xFF6D28D9) : Colors.white;

    final canCheck = controller.canCheck;
    final canContinue = controller.canContinue;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: panelColor,
        border: Border.all(color: Colors.white.withOpacity(0.22)),
        boxShadow: isChecked
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isChecked ? Icons.verified_rounded : Icons.info_outline_rounded,
            color: textColor.withOpacity(0.95),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isChecked ? 'Đã lưu câu trả lời' : 'Chọn/nhập câu trả lời rồi bấm CHECK',
              style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          if (!isChecked)
            _PrimaryBtn(
              label: 'CHECK',
              enabled: canCheck,
              onTap: canCheck ? controller.onCheck : null,
            )
          else
            _PrimaryBtn(
              label: 'CONTINUE',
              enabled: canContinue,
              onTap: canContinue ? controller.onContinue : null,
            ),
        ],
      ),
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
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: enabled ? const Color(0xFF6D28D9) : Colors.white.withOpacity(0.18),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/* =========================
   COMPLETED VIEW (Optimistic + results + retry)
========================= */

class _CompletedView extends StatelessWidget {
  final LessonController controller;
  final VoidCallback onGoCurriculum;

  const _CompletedView({
    required this.controller,
    required this.onGoCurriculum,
  });

  @override
  Widget build(BuildContext context) {
    final optimistic = controller.isOptimisticSubmitting;
    final optimisticErr = controller.optimisticError;
    final r = controller.submitResult;

    final percent = r?.scorePercent ?? 0;
    final points = r?.scorePoints ?? 0;
    final max = r?.maxPoints ?? 0;

    final results = r?.results ?? const <ItemResult>[];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            _GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(optimistic ? Icons.hourglass_top_rounded : Icons.emoji_events_rounded,
                        color: Colors.white, size: 44),
                    const SizedBox(height: 10),
                    Text(
                      optimistic ? 'Đang chấm điểm…' : 'Hoàn thành lesson!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                    ),
                    const SizedBox(height: 10),
                    if (optimistic)
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    else
                      Text(
                        '$percent%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 44),
                      ),
                    const SizedBox(height: 6),
                    if (!optimistic)
                      Text(
                        '$points/$max điểm',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800),
                      )
                    else
                      Text(
                        'Bạn có thể quay lại Curriculum, hệ thống vẫn đang chấm.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800),
                      ),
                    const SizedBox(height: 14),

                    if (optimisticErr != null) ...[
                      _SoftInfo(text: optimisticErr),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: controller.retrySubmit,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Retry submit',
                          style: TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    FilledButton.icon(
                      onPressed: onGoCurriculum,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF6D28D9)),
                      label: const Text(
                        'Quay lại Curriculum',
                        style: TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!optimistic && r != null) ...[
              const SizedBox(height: 14),
              _GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.fact_check_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Kết quả theo từng câu',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                      _Pill(text: '${results.length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final it in results) ...[
                _ResultRow(res: it),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final ItemResult res;
  const _ResultRow({required this.res});

  @override
  Widget build(BuildContext context) {
    final ok = res.isCorrect;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_rounded : Icons.cancel_rounded, color: ok ? Colors.greenAccent : Colors.redAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Item ${res.itemId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 10),
          _Pill(text: '${res.earnedPoints}/${res.maxPoints}'),
        ],
      ),
    );
  }
}

/* =========================
   Helpers UI
========================= */

class _HintCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HintCard({required this.icon, required this.text});

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
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, height: 1.25)),
          ),
        ],
      ),
    );
  }
}

class _MiniMetaRow extends StatelessWidget {
  final String left;
  final Object right; // String or Widget

  const _MiniMetaRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(left, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800)),
        ),
        if (right is String)
          Text(right as String, style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w800))
        else
          (right as Widget),
      ],
    );
  }
}

class _Opt {
  final String id;
  final String text;
  _Opt({required this.id, required this.text});
}

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

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _VocabCTAButton extends StatelessWidget {
  final String lessonId;

  const _VocabCTAButton({required this.lessonId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          context.go('/vocab/lesson/$lessonId');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.menu_book_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Học từ vựng trong bài này',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
