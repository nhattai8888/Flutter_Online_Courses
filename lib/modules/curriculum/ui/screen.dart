import 'package:flutter/material.dart';
import '../data/api.dart';
import '../data/repository_impl.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';
import 'controller.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notify/app_toast.dart';

class CurriculumScreen extends StatefulWidget {
  final CurriculumController? controller;
  const CurriculumScreen({super.key, this.controller});

  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  late final CurriculumController controller;

  final _scroll = ScrollController();

  String? _lastError;

  @override
  void initState() {
    super.initState();

    final repo = CurriculumRepositoryImpl(CurriculumApi());
    controller =
        widget.controller ??
        CurriculumController(
          listLanguages: ListLanguagesUseCase(repo),
          listLevels: ListLevelsByLanguageUseCase(repo),
          listUnits: ListUnitsByLanguageUseCase(repo),
          listLessonsByUnit: ListLessonsByUnitUseCase(repo),
          getLesson: GetLessonUseCase(repo),
        );

    controller.addListener(_onControllerChanged);
    _scroll.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.init());
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      controller.loadMoreLessons();
    }
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final err = controller.error;

    if (err != null && err.isNotEmpty && err != _lastError) {
      _lastError = err;
      AppToast.show(context, message: err, type: AppToastType.error);
    }
  }

  void _startFirstLesson() {
    final publishedLessons = controller.lessons
        .where((l) => l.publishStatus == PublishStatus.published)
        .toList();
    if (publishedLessons.isEmpty) return;
    final first = publishedLessons.first;
    AppToast.show(
      context,
      message: 'Start: ${first.title}',
      type: AppToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Duolingo-ish / Purple palette
    const purple = Color(0xFF6D28D9);
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
                  colors: [purple, purple2],
                ),
              ),
            ),
          ),
          // Soft blobs
          const Positioned(
            top: -90,
            left: -70,
            child: _Blob(size: 240, color: Colors.white24),
          ),
          const Positioned(
            bottom: -110,
            right: -80,
            child: _Blob(size: 300, color: Colors.white12),
          ),

          SafeArea(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final isInitialLoading =
                    controller.status == CurriculumStatus.loading &&
                    controller.languages.isEmpty;

                // Only show lessons that are published
                final publishedLessons = controller.lessons
                    .where((l) => l.publishStatus == PublishStatus.published)
                    .toList();

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: CustomScrollView(
                      controller: _scroll,
                      slivers: [
                        SliverAppBar(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          pinned: true,
                          centerTitle: true,
                          title: const Text(
                            'Ngôn ngữ của tôi',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          actions: [
                            IconButton(
                              onPressed:
                                  controller.status == CurriculumStatus.loading
                                  ? null
                                  : controller.loadLanguages,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Refresh',
                            ),
                            const SizedBox(width: 6),
                          ],
                        ),

                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              // Hero
                              _GlassCard(
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      _HeroBadge(
                                        title: 'Ngôn ngữ',
                                        subtitle:
                                            '${controller.lessons.length}',
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Vui lòng chọn Ngôn Ngữ để học',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              if (isInitialLoading) const _SkeletonDuolingo(),

                              if (!isInitialLoading &&
                                  controller.languages.isEmpty) ...[
                                _EmptyState(onRetry: controller.loadLanguages),
                              ] else if (!isInitialLoading) ...[
                                // Language
                                const _SectionHeader(
                                  icon: Icons.language_rounded,
                                  title: 'Ngôn ngữ',
                                ),
                                const SizedBox(height: 8),
                                _ChipsRow<Language>(
                                  items: controller.languages,
                                  isSelected: (x) =>
                                      x.id == controller.selectedLanguage?.id,
                                  label: (x) => x.name,
                                  onTap: (x) => controller.selectLanguage(x),
                                ),
                                const SizedBox(height: 16),

                                // Level
                                const _SectionHeader(
                                  icon: Icons.stairs_rounded,
                                  title: 'Trình độ',
                                ),
                                const SizedBox(height: 8),
                                _ChipsRow<Level>(
                                  items: controller.levels,
                                  isSelected: (x) =>
                                      x.id == controller.selectedLevel?.id,
                                  label: (x) => '${x.code} - ${x.name}',
                                  onTap: (x) => controller.selectLevel(x),
                                ),
                                const SizedBox(height: 16),

                                // Units
                                Row(
                                  children: [
                                    const _SectionHeader(
                                      icon: Icons.view_agenda_rounded,
                                      title: 'Bài học',
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: controller.selectedUnit == null
                                          ? null
                                          : () => controller.selectUnit(null),
                                      icon: const Icon(
                                        Icons.clear_rounded,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        'Xóa',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _UnitCards(
                                  units: controller.units,
                                  selectedUnitId: controller.selectedUnit?.id,
                                  onTap: (u) => controller.selectUnit(u),
                                ),
                                const SizedBox(height: 18),

                                // Lessons (Duolingo Path)
                                Row(
                                  children: [
                                    const _SectionHeader(
                                      icon: Icons.route_rounded,
                                      title: 'Lộ trình học tập',
                                    ),
                                    const Spacer(),
                                    _CountPill(
                                      count: controller.lessons
                                          .where(
                                            (l) =>
                                                l.publishStatus ==
                                                PublishStatus.published,
                                          )
                                          .length,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                if (publishedLessons.isEmpty &&
                                    !controller.loadingMore) ...[
                                  const _SoftInfo(
                                    text: 'Chưa có lesson cho bộ lọc hiện tại.',
                                  ),
                                ] else ...[
                                  _DuolingoPath(
                                    lessons: publishedLessons,
                                    onTapLesson: (lesson) {
                                      context.go('/lesson/${lesson.id}');
                                    },
                                  ),
                                ],

                                if (controller.loadingMore) ...[
                                  const SizedBox(height: 12),
                                  const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],

                                if (!controller.loadingMore &&
                                    !controller.hasMoreLessons &&
                                    controller.lessons.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const _SoftInfo(
                                    text: 'Hết danh sách lesson.',
                                  ),
                                ],
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: _StartButtonWithBounce(
        onPressed: controller.lessons.isEmpty ? null : _startFirstLesson,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _StartButtonWithBounce extends StatefulWidget {
  final VoidCallback? onPressed;

  const _StartButtonWithBounce({required this.onPressed});

  @override
  State<_StartButtonWithBounce> createState() => _StartButtonWithBounceState();
}

class _StartButtonWithBounceState extends State<_StartButtonWithBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 20, 80),
      child: AnimatedBuilder(
        animation: _bounceCtrl,
        builder: (_, __) {
          final bounce = Curves.easeInOut.transform(_bounceCtrl.value);
          final offset = 6 * (bounce - 0.5) * 2;

          return Transform.translate(
            offset: Offset(0, offset),
            child: FloatingActionButton.small(
              onPressed: widget.onPressed,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),

              child: const Icon(Icons.play_arrow_rounded),
            ),
          );
        },
      ),
    );
  }
}

/* =========================
   UI COMPONENTS (DUOLINGO STYLE)
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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
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

class _HeroBadge extends StatelessWidget {
  final String title;
  final String subtitle;
  const _HeroBadge({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.white),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

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
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ChipsRow<T> extends StatelessWidget {
  final List<T> items;
  final bool Function(T) isSelected;
  final String Function(T) label;
  final void Function(T) onTap;

  const _ChipsRow({
    required this.items,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D28D9);

    if (items.isEmpty) {
      return const _SoftInfo(text: 'Chưa có dữ liệu.');
    }

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final it = items[i];
          final selected = isSelected(it);
          return Container(
            decoration: selected
                ? BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: purple.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  )
                : null,
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) => onTap(it),
              label: Text(label(it)),
              labelStyle: TextStyle(
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                color: purple,
              ),
              selectedColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.12),
              shape: StadiumBorder(
                side: BorderSide(
                  color: Colors.white.withOpacity(selected ? 0.0 : 0.28),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UnitCards extends StatelessWidget {
  final List<Unit> units;
  final String? selectedUnitId;
  final void Function(Unit) onTap;

  const _UnitCards({
    required this.units,
    required this.selectedUnitId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (units.isEmpty) {
      return const _SoftInfo(text: 'Chưa có unit cho level hiện tại.');
    }

    return Column(
      children: units.map((u) {
        final selected = u.id == selectedUnitId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onTap(u),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: selected ? Colors.white : Colors.white.withOpacity(0.14),
                border: Border.all(
                  color: Colors.white.withOpacity(selected ? 0.0 : 0.22),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? const Color(0xFF6D28D9)
                          : Colors.white.withOpacity(0.18),
                    ),
                    child: Icon(
                      Icons.view_agenda_rounded,
                      color: selected ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: selected
                                ? const Color(0xFF111827)
                                : Colors.white,
                          ),
                        ),
                        if ((u.description ?? '').isNotEmpty)
                          Text(
                            u.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  (selected
                                          ? const Color(0xFF111827)
                                          : Colors.white)
                                      .withOpacity(0.78),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.chevron_right_rounded,
                    color: selected
                        ? const Color(0xFF6D28D9)
                        : Colors.white.withOpacity(0.9),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DuolingoPath extends StatelessWidget {
  final List<Lesson> lessons;
  final void Function(Lesson) onTapLesson;

  const _DuolingoPath({required this.lessons, required this.onTapLesson});

  @override
  Widget build(BuildContext context) {
    // Path layout: alternate left/right to mimic Duolingo
    return Column(
      children: List.generate(lessons.length, (i) {
        final lesson = lessons[i];
        final isLeft = i % 2 == 0;
        final isLast = i == lessons.length - 1;

        return _PathNode(
          lesson: lesson,
          alignLeft: isLeft,
          showConnector: !isLast,
          onTap: () => onTapLesson(lesson),
        );
      }),
    );
  }
}

class _PathNode extends StatelessWidget {
  final Lesson lesson;
  final bool alignLeft;
  final bool showConnector;
  final VoidCallback onTap;

  const _PathNode({
    required this.lesson,
    required this.alignLeft,
    required this.showConnector,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Icon mapping
    final IconData icon = switch (lesson.lessonType) {
      LessonType.boss => Icons.shield_rounded,
      LessonType.review => Icons.refresh_rounded,
      LessonType.standard => Icons.school_rounded,
    };

    final String status = switch (lesson.publishStatus) {
      PublishStatus.published => 'PUBLISHED',
      PublishStatus.review => 'REVIEW',
      PublishStatus.archived => 'ARCHIVED',
      PublishStatus.draft => 'DRAFT',
    };

    // Node color
    final Color nodeColor = switch (lesson.lessonType) {
      LessonType.boss => const Color(0xFFFFD166), // vàng boss
      LessonType.review => const Color(0xFF2DD4BF), // teal review
      LessonType.standard => Colors.white, // trắng standard
    };

    final Color textOnNode = lesson.lessonType == LessonType.standard
        ? const Color(0xFF6D28D9)
        : const Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        children: [
          // Connector line (center)
          if (showConnector)
            Positioned(
              left: 0,
              right: 0,
              top: 56,
              child: Center(
                child: Container(
                  width: 4,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),

          Row(
            mainAxisAlignment: alignLeft
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onTap,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.22)),
                  ),
                  child: Row(
                    children: [
                      // Node circle
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: nodeColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: textOnNode),
                      ),
                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lesson.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${lesson.estimatedMinutes} phút',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            if ((lesson.objective ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                lesson.objective!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonDuolingo extends StatelessWidget {
  const _SkeletonDuolingo();

  @override
  Widget build(BuildContext context) {
    Widget block(double h) => Container(
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
    );

    return Column(
      children: [
        block(90),
        const SizedBox(height: 12),
        block(46),
        const SizedBox(height: 16),
        block(46),
        const SizedBox(height: 16),
        block(180),
        const SizedBox(height: 16),
        block(240),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _EmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 44, color: Colors.white),
            const SizedBox(height: 10),
            const Text(
              'Chưa có dữ liệu curriculum.',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Load'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 115, 89, 231),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
