import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/api.dart';
import '../data/repository_impl.dart';
import '../domain/usecases.dart';
import 'controller.dart';

class VocabularyScreen extends StatefulWidget {
  final String? lessonId;
  final String? lexemeId;

  const VocabularyScreen({super.key, this.lessonId, this.lexemeId});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> {
  late final VocabularyController controller;

  @override
  void initState() {
    super.initState();

    final repo = VocabularyRepositoryImpl(VocabularyApi());
    controller = VocabularyController(
      listLexemesByLesson: ListLexemesByLessonUseCase(repo),
      getLexeme: GetLexemeUseCase(repo),
      listSensesByLexeme: ListSensesByLexemeUseCase(repo),
      listExamplesBySense: ListExamplesBySenseUseCase(repo),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.init(lessonId: widget.lessonId, lexemeId: widget.lexemeId);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _openListSheet() {
    final lexemes = controller.lexemes;
    if (lexemes.isEmpty) return;

    HapticFeedback.selectionClick();

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7F7FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        final selected = controller.selectedLexeme;
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 20),
            itemCount: lexemes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final l = lexemes[i];
              final isSelected = selected?.id == l.id;
              return ListTile(
                onTap: () {
                  Navigator.of(context).pop();
                  controller.selectLexeme(l);
                },
                title: Text(
                  l.lemma,
                  style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800),
                ),
                subtitle: Text(_mapLexemeTypeVi(l.type.name)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded)
                    : const Icon(Icons.chevron_right_rounded),
              );
            },
          ),
        );
      },
    );
  }

  String _progressText() {
    final total = controller.lexemes.length;
    if (total == 0) return '';
    final idx = _selectedIndex();
    return '${idx + 1}/$total';
  }

  double _progressValue() {
    final total = controller.lexemes.length;
    if (total == 0) return 0;
    final idx = _selectedIndex();
    return ((idx + 1) / total).clamp(0.0, 1.0);
  }

  int _selectedIndex() {
    final selected = controller.selectedLexeme;
    if (selected == null) return 0;
    final i = controller.lexemes.indexWhere((e) => e.id == selected.id);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    const purple1 = Color(0xFF6D28D9);
    const purple2 = Color(0xFF8B5CF6);

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [purple1, purple2],
                ),
              ),
            ),
          ),

          // Soft iOS blur overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.white.withOpacity(0.04)),
            ),
          ),

          // Light blobs
          const Positioned(top: -70, left: -60, child: _Blob(size: 210, color: Colors.white24)),
          const Positioned(bottom: -90, right: -70, child: _Blob(size: 260, color: Colors.white12)),

          SafeArea(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final status = controller.status;

                return Column(
                  children: [
                    _TopBarIOS(
                      title: widget.lessonId != null ? 'Danh sách từ' : 'Chi tiết từ',
                      subtitle: widget.lessonId != null ? 'Từ vựng theo bài học' : null,
                      onBack: () => Navigator.of(context).maybePop(),
                      onOpenList: _openListSheet,
                      progressText: _progressText(),
                      progressValue: _progressValue(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        child: _BodyIOS(
                          status: status,
                          controller: controller,
                        ),
                      ),
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

/* =========================
   TOP BAR iOS STYLE
========================= */

class _TopBarIOS extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final VoidCallback onOpenList;
  final String progressText;
  final double progressValue;

  const _TopBarIOS({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onOpenList,
    required this.progressText,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              ),
              Expanded(
                child: Column(
                  children: [
                    if ((subtitle ?? '').isNotEmpty)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              _TopListButton(onTap: onOpenList),
              const SizedBox(width: 10),
              SizedBox(
                width: 56,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    progressText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),

          // progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: progressText.isEmpty ? null : progressValue,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.95)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopListButton extends StatelessWidget {
  final VoidCallback onTap;
  const _TopListButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.92),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFF111827)),
              SizedBox(width: 6),
              Text('LIST', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827))),
            ],
          ),
        ),
      ),
    );
  }
}

/* =========================
   BODY iOS
========================= */

class _BodyIOS extends StatelessWidget {
  final VocabularyStatus status;
  final VocabularyController controller;

  const _BodyIOS({
    required this.status,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (status == VocabularyStatus.loading) {
      return const Center(
        child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }

    if (status == VocabularyStatus.error) {
      return _GlassShell(
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.error ?? 'Lỗi',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 720;

    if (!isMobile) {
      // Desktop/tablet view giữ nguyên cấu trúc
      return _LegacyLayout(controller: controller);
    }

    if (controller.lexemes.isEmpty) {
      return const _GlassShell(
        child: Center(
          child: Text('Chưa có dữ liệu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      );
    }

    return _FlashcardStageIOS(controller: controller);
  }
}

/* =========================
   MOBILE FLASHCARD iOS + SWIPE
========================= */

class _FlashcardStageIOS extends StatefulWidget {
  final VocabularyController controller;
  const _FlashcardStageIOS({required this.controller});

  @override
  State<_FlashcardStageIOS> createState() => _FlashcardStageIOSState();
}

class _FlashcardStageIOSState extends State<_FlashcardStageIOS> {
  late final PageController _page;
  int _index = 0;

  VoidCallback? _controllerListener;

  @override
  void initState() {
    super.initState();

    _index = _selectedIndex();
    _page = PageController(viewportFraction: 0.92, initialPage: _index);

    _controllerListener = () {
      if (!mounted) return;
      final idx = _selectedIndex();
      if (idx != _index && _page.hasClients) {
        setState(() => _index = idx);
        _page.animateToPage(
          idx,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
        );
      }
    };

    widget.controller.addListener(_controllerListener!);
  }

  @override
  void dispose() {
    if (_controllerListener != null) {
      widget.controller.removeListener(_controllerListener!);
    }
    _page.dispose();
    super.dispose();
  }

  int _selectedIndex() {
    final c = widget.controller;
    final list = c.lexemes;
    if (list.isEmpty) return 0;
    final sel = c.selectedLexeme;
    if (sel == null) return 0;
    final i = list.indexWhere((e) => e.id == sel.id);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final lexemes = c.lexemes;
    if (lexemes.isEmpty) {
      return const Center(
        child: Text('Chưa có từ vựng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      );
    }

    // Ensure selectedLexeme sync with index
    final safeIndex = _index.clamp(0, lexemes.length - 1);
    if (c.selectedLexeme == null || lexemes[safeIndex].id != c.selectedLexeme!.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        c.selectLexeme(lexemes[safeIndex]);
      });
    }

    return Column(
      children: [
        const SizedBox(height: 6),

        Expanded(
          child: PageView.builder(
            controller: _page,
            itemCount: lexemes.length,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              setState(() => _index = i);
              c.selectLexeme(lexemes[i]);
            },
            itemBuilder: (_, i) {
              final l = lexemes[i];
              final isActive = i == _index;

              final levelText = 'Trình độ: Lv ${l.difficulty}';
              final typeTag = _mapLexemeTypeVi(l.type.name);

              final topicTag = isActive
                  ? _mapDomainVi(c.senses.isNotEmpty ? (c.senses.first.domain ?? '') : '')
                  : '...';

              final senses = isActive ? c.senses : const [];
              final example = isActive && c.examples.isNotEmpty ? c.examples.first.sentence : null;

              if (isActive && senses.isNotEmpty && c.expandedSenseId == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  c.toggleSenseExamples(senses.first);
                });
              }

              return AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: isActive ? 10 : 20,
                ),
                child: _StackedCardsIOS(
                  highlight: isActive,
                  child: _Flip3DCard(
                    front: _FlashcardFrontIOS(
                      lemma: l.lemma,
                      phonetic: l.phonetic,
                      levelText: levelText,
                      topicTag: topicTag,
                      typeTag: typeTag,
                    ),
                    back: _FlashcardBackIOS(
                      lemma: l.lemma,
                      levelText: levelText,
                      topicTag: topicTag,
                      typeTag: typeTag,
                      senses: senses,
                      example: example,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
        Text(
          'Vuốt để chuyển từ • Chạm để lật thẻ',
          style: TextStyle(color: Colors.white.withOpacity(0.92), fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

/* =========================
   FIX FLIP (NO MIRROR TEXT)
========================= */

class _Flip3DCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  const _Flip3DCard({
    required this.front,
    required this.back,
  });

  @override
  State<_Flip3DCard> createState() => _Flip3DCardState();
}

class _Flip3DCardState extends State<_Flip3DCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_c.isAnimating) return;
    HapticFeedback.lightImpact();
    _c.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _isFront = !_isFront);
      _c.value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value;

          // 0..0.5 rotate 0..90, then swap, 0.5..1 rotate -90..0
          final firstHalf = t <= 0.5;
          final angle = firstHalf
              ? (math.pi / 2) * (t / 0.5)
              : -(math.pi / 2) * ((1 - t) / 0.5);

          final showingFront = firstHalf ? _isFront : !_isFront;
          final child = showingFront ? widget.front : widget.back;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(angle),
            child: child,
          );
        },
      ),
    );
  }
}

/* =========================
   CARD STACK (HIGHLIGHT)
========================= */

class _StackedCardsIOS extends StatelessWidget {
  final Widget child;
  final bool highlight;

  const _StackedCardsIOS({
    required this.child,
    required this.highlight,
  });

  static const double _cardWidth = 360;
  static const double _cardHeight = 440;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: _cardWidth,
        height: _cardHeight + 30, // dư chỗ cho stacked shadow
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Card layer 3 (dưới)
            Transform.translate(
              offset: const Offset(0, 18),
              child: Transform.scale(
                scale: 0.95,
                child: _PaperCardIOS(
                  shadowOpacity: 0.05,
                  borderOpacity: 0.55,
                  child: const SizedBox(
                    width: _cardWidth,
                    height: _cardHeight,
                  ),
                ),
              ),
            ),

            // Card layer 2
            Transform.translate(
              offset: const Offset(0, 9),
              child: Transform.scale(
                scale: 0.975,
                child: _PaperCardIOS(
                  shadowOpacity: 0.07,
                  borderOpacity: 0.65,
                  child: const SizedBox(
                    width: _cardWidth,
                    height: _cardHeight,
                  ),
                ),
              ),
            ),

            // Card chính
            _PaperCardIOS(
              shadowOpacity: highlight ? 0.18 : 0.12,
              borderOpacity: highlight ? 1.0 : 0.9,
              child: SizedBox(
                width: _cardWidth,
                height: _cardHeight,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperCardIOS extends StatelessWidget {
  final Widget child;
  final double shadowOpacity;
  final double borderOpacity;

  const _PaperCardIOS({
    required this.child,
    required this.shadowOpacity,
    required this.borderOpacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB).withOpacity(borderOpacity)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(shadowOpacity),
            blurRadius: 20,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }
}

/* =========================
   CARD CONTENT (CENTER + PADDING)
========================= */

class _FlashcardFrontIOS extends StatelessWidget {
  final String lemma;
  final String? phonetic;
  final String levelText;
  final String topicTag;
  final String typeTag;

  const _FlashcardFrontIOS({
    required this.lemma,
    required this.phonetic,
    required this.levelText,
    required this.topicTag,
    required this.typeTag,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TagRow(levelText: levelText, topicTag: topicTag, typeTag: typeTag),
          const SizedBox(height: 18),
          Text(
            lemma,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 34,
              color: Color(0xFF111827),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          if ((phonetic ?? '').isNotEmpty)
            Text(
              phonetic!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Color(0xFF6B7280),
              ),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets_rounded, color: Color(0xFF6D28D9), size: 20),
                SizedBox(width: 8),
                Text(
                  'Nhớ phát âm nhé!',
                  style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashcardBackIOS extends StatelessWidget {
  final String lemma;
  final String levelText;
  final String topicTag;
  final String typeTag;
  final List<dynamic> senses;
  final String? example;

  const _FlashcardBackIOS({
    required this.lemma,
    required this.levelText,
    required this.topicTag,
    required this.typeTag,
    required this.senses,
    required this.example,
  });

  @override
  Widget build(BuildContext context) {
    final meanings = senses.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TagRow(levelText: levelText, topicTag: topicTag, typeTag: typeTag),
          const SizedBox(height: 14),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nghĩa',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 10),

          if (meanings.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chưa có nghĩa.',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6B7280)),
              ),
            )
          else
            ...List.generate(meanings.length, (i) {
              final s = meanings[i];
              final def = (s.definition ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${i + 1}. $def',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF111827),
                      height: 1.25,
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 14),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ví dụ',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(height: 8),

          if ((example ?? '').isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                example!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            )
          else
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Chưa có ví dụ (đang tải hoặc không có).',
                style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF)),
              ),
            ),

          const Spacer(),

          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              'Chạm để lật lại',
              style: TextStyle(
                color: const Color(0xFF6B7280).withOpacity(0.85),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final String levelText;
  final String topicTag;
  final String typeTag;

  const _TagRow({
    required this.levelText,
    required this.topicTag,
    required this.typeTag,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniTag(text: levelText),
        _MiniTag(text: 'Chủ đề: $topicTag'),
        _MiniTag(text: 'Loại: $typeTag'),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: Color(0xFF111827),
        ),
      ),
    );
  }
}

/* =========================
   DESKTOP/TABLET (KEEP STRUCTURE)
========================= */

class _LegacyLayout extends StatelessWidget {
  final VocabularyController controller;
  const _LegacyLayout({required this.controller});

  @override
  Widget build(BuildContext context) {
    final lexemes = controller.lexemes;
    final selected = controller.selectedLexeme;

    return Row(
      children: [
        if (lexemes.isNotEmpty) ...[
          Expanded(
            flex: 4,
            child: _GlassShell(
              child: ListView.separated(
                itemCount: lexemes.length,
                separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.14)),
                itemBuilder: (_, i) {
                  final l = lexemes[i];
                  final isSelected = selected?.id == l.id;
                  return ListTile(
                    onTap: () => controller.selectLexeme(l),
                    dense: true,
                    title: Text(
                      l.lemma,
                      style: TextStyle(color: Colors.white, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800),
                    ),
                    subtitle: Text(
                      _mapLexemeTypeVi(l.type.name).toUpperCase(),
                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.9)),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 7,
          child: _LexemeDetailLegacy(controller: controller),
        ),
      ],
    );
  }
}

class _LexemeDetailLegacy extends StatelessWidget {
  final VocabularyController controller;
  const _LexemeDetailLegacy({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = controller.selectedLexeme;
    if (l == null) {
      return const _GlassShell(
        child: Center(
          child: Text('Chọn 1 từ để xem chi tiết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      );
    }

    return _GlassShell(
      child: ListView(
        children: [
          Text(l.lemma, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 6),
          Row(
            children: [
              _Pill(text: _mapLexemeTypeVi(l.type.name).toUpperCase()),
              const SizedBox(width: 8),
              _Pill(text: 'Lv ${l.difficulty}'),
              if ((l.phonetic ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                _Pill(text: l.phonetic!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Text('Nghĩa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (controller.senses.isEmpty)
            Text('Chưa có nghĩa', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700))
          else
            ...controller.senses.map((s) {
              final expanded = controller.expandedSenseId == s.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => controller.toggleSenseExamples(s),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${s.senseIndex}. ${s.definition}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                              ),
                            ),
                            Icon(expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                color: Colors.white.withOpacity(0.9)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Chủ đề: ${_mapDomainVi(s.domain)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.86), fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 10),
                          const Text('Ví dụ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          if (controller.examples.isEmpty)
                            Text('Đang tải/Chưa có ví dụ...', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                          ...controller.examples.map((ex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '• ${ex.sentence}',
                                style: TextStyle(color: Colors.white.withOpacity(0.95), fontWeight: FontWeight.w700),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/* =========================
   SMALL UI HELPERS
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

class _GlassShell extends StatelessWidget {
  final Widget child;
  const _GlassShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: child,
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
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }
}

/* =========================
   ENUM MAPPING (VIETNAMESE)
========================= */

String _mapDomainVi(String raw) {
  final v = raw.trim().toUpperCase();
  switch (v) {
    case 'DAILY':
      return 'Hằng ngày';
    case 'ACADEMIC':
      return 'Học thuật';
    case 'BUSINESS':
      return 'Kinh doanh';
    case 'TRAVEL':
      return 'Du lịch';
    case 'TECH':
      return 'Công nghệ';
    case 'OTHER':
    default:
      return 'Khác';
  }
}

String _mapLexemeTypeVi(String raw) {
  final v = raw.trim().toUpperCase();
  switch (v) {
    case 'NOUN':
      return 'Danh từ';
    case 'VERB':
      return 'Động từ';
    case 'ADJ':
      return 'Tính từ';
    case 'ADV':
      return 'Trạng từ';
    case 'PREP':
      return 'Giới từ';
    case 'PHRASE':
      return 'Cụm từ';
    case 'OTHER':
      return 'Khác';
    case 'WORD':
      return 'Từ';
    case 'IDIOM':
      return 'Thành ngữ';
    default:
      return 'Khác';
  }
}
