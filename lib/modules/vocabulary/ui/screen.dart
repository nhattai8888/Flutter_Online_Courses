import 'package:flutter/material.dart';

import '../data/api.dart';
import '../data/repository_impl.dart';
import '../domain/entity.dart';
import '../domain/usecases.dart';
import 'controller.dart';

class VocabularyScreen extends StatefulWidget {
  final VocabularyController? controller;

  /// NOTE: For real usage, pass languageId from Curriculum selection.
  final String languageId;

  const VocabularyScreen({
    super.key,
    this.controller,
    required this.languageId,
  });

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen> with TickerProviderStateMixin {
  late final VocabularyController controller;
  final _search = TextEditingController();
  String? _lastSnack;

  @override
  void initState() {
    super.initState();

    final repo = VocabularyRepositoryImpl(VocabularyApi());
    controller = widget.controller ??
        VocabularyController(
          listLexemes: ListLexemesUseCase(repo),
          getLexeme: GetLexemeUseCase(repo),
          listSensesByLexeme: ListSensesByLexemeUseCase(repo),
          listExamplesBySense: ListExamplesBySenseUseCase(repo),
          getReviewToday: GetReviewTodayUseCase(repo),
          submitReviewResult: SubmitReviewResultUseCase(repo),
          getWeakWords: GetWeakWordsUseCase(repo),
        );

    controller.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.init(languageId: widget.languageId);
    });
  }

  @override
  void dispose() {
    controller.removeListener(_onChanged);
    _search.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    final err = controller.error;
    if (err != null && err.isNotEmpty && err != _lastSnack) {
      _lastSnack = err;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      });
    }
  }

  Color _primary(BuildContext context) => Theme.of(context).colorScheme.primary;

  Future<void> _openLexemeDetail(Lexeme lex) async {
    await controller.openLexeme(lex.id);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _LexemeDetailSheet(primary: _primary(context), controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = _primary(context);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Vocabulary', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surface,
        actions: [
          IconButton(
            onPressed: () async {
              await controller.preloadSidePanels();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã cập nhật Review/Weak Words')));
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => controller.setQuery(v),
                    decoration: InputDecoration(
                      hintText: 'Tìm từ… (lemma)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest.withOpacity(0.6),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      _InfoChip(
                        primary: primary,
                        icon: Icons.inventory_2_rounded,
                        title: 'Review',
                        value: '${controller.reviewToday?.total ?? 0}',
                        onTap: () => _openReviewToday(context, primary),
                      ),
                      const SizedBox(width: 10),
                      _InfoChip(
                        primary: primary,
                        icon: Icons.warning_amber_rounded,
                        title: 'Weak',
                        value: '${controller.weakWords.length}',
                        onTap: () => _openWeakWords(context, primary),
                      ),
                      const Spacer(),
                      if (controller.status == VocabularyStatus.loading)
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
                    ],
                  ),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.pixels > n.metrics.maxScrollExtent - 240) {
                        controller.loadMore();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: controller.items.length + (controller.loadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        if (i >= controller.items.length) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
                              ),
                            ),
                          );
                        }

                        final lex = controller.items[i];
                        return _LexemeCard(
                          primary: primary,
                          lexeme: lex,
                          onTap: () => _openLexemeDetail(lex),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primary,
        onPressed: () => _openReviewToday(context, primary),
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: const Text('Start Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Future<void> _openReviewToday(BuildContext context, Color primary) async {
    await controller.preloadSidePanels();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _ReviewTodaySheet(primary: primary, controller: controller),
    );
  }

  Future<void> _openWeakWords(BuildContext context, Color primary) async {
    await controller.preloadSidePanels();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _WeakWordsSheet(primary: primary, controller: controller),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final Color primary;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _InfoChip({
    required this.primary,
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: primary.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: primary, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
              const SizedBox(width: 8),
              Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: primary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LexemeCard extends StatelessWidget {
  final Color primary;
  final Lexeme lexeme;
  final VoidCallback onTap;

  const _LexemeCard({required this.primary, required this.lexeme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cs.surfaceContainerHighest.withOpacity(0.35),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withOpacity(0.14)),
                child: Icon(Icons.translate_rounded, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lexeme.lemma,
                      style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${lexeme.type} • difficulty ${lexeme.difficulty}',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.70), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _LexemeDetailSheet extends StatelessWidget {
  final Color primary;
  final VocabularyController controller;

  const _LexemeDetailSheet({required this.primary, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lex = controller.selectedLexeme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          final lexeme = lex ?? controller.selectedLexeme;
          if (lexeme == null) {
            return const SizedBox(height: 240, child: Center(child: Text('No data')));
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(color: cs.outlineVariant.withOpacity(0.6), borderRadius: BorderRadius.circular(99)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lexeme.lemma,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cs.onSurface),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: primary.withOpacity(0.3)),
                    ),
                    child: Text(lexeme.type, style: TextStyle(fontWeight: FontWeight.w900, color: primary)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in controller.senses) ...[
                      _SenseCard(
                        primary: primary,
                        sense: s,
                        examples: controller.examplesBySenseId[s.id] ?? const [],
                        onLoadExamples: () => controller.loadExamplesForSense(s.id),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (controller.senses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Text('Chưa có senses.', style: TextStyle(color: cs.outline, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: primary),
                      onPressed: () async {
                        await controller.rateReviewCard(lexemeId: lexeme.id, rating: 5, source: 'QUIZ');
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: const Text('Mastered', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await controller.rateReviewCard(lexemeId: lexeme.id, rating: 0, source: 'QUIZ');
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.close_rounded, color: cs.onSurface),
                      label: Text('Fail', style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SenseCard extends StatelessWidget {
  final Color primary;
  final Sense sense;
  final List<ExampleSentence> examples;
  final VoidCallback onLoadExamples;

  const _SenseCard({
    required this.primary,
    required this.sense,
    required this.examples,
    required this.onLoadExamples,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: cs.surfaceContainerHighest.withOpacity(0.35),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: primary.withOpacity(0.25)),
                ),
                child: Text(
                  '#${sense.senseIndex} • ${sense.domain}',
                  style: TextStyle(fontWeight: FontWeight.w900, color: primary),
                ),
              ),
              const Spacer(),
              Text(
                sense.status,
                style: TextStyle(color: cs.outline, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            sense.definition,
            style: TextStyle(fontWeight: FontWeight.w800, color: cs.onSurface, height: 1.2),
          ),
          const SizedBox(height: 10),
          if (examples.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onLoadExamples,
                icon: const Icon(Icons.library_books_rounded),
                label: const Text('Load examples', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Examples', style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                const SizedBox(height: 8),
                for (final ex in examples.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${ex.sentence}', style: TextStyle(color: cs.onSurface.withOpacity(0.86), fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ReviewTodaySheet extends StatelessWidget {
  final Color primary;
  final VocabularyController controller;

  const _ReviewTodaySheet({required this.primary, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final data = controller.reviewToday;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(color: cs.outlineVariant.withOpacity(0.6), borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Review Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close_rounded, color: cs.outline)),
            ],
          ),
          const SizedBox(height: 8),
          if (data == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('Chưa có dữ liệu.', style: TextStyle(color: cs.outline, fontWeight: FontWeight.w700)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: data.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final card = data.items[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: cs.surfaceContainerHighest.withOpacity(0.35),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withOpacity(0.14)),
                          child: Icon(Icons.flash_on_rounded, color: primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            card.lexeme.lemma,
                            style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
                          ),
                        ),
                        _RateBtn(primary: primary, label: '0', onTap: () => controller.rateReviewCard(lexemeId: card.lexeme.id, rating: 0)),
                        const SizedBox(width: 6),
                        _RateBtn(primary: primary, label: '3', onTap: () => controller.rateReviewCard(lexemeId: card.lexeme.id, rating: 3)),
                        const SizedBox(width: 6),
                        _RateBtn(primary: primary, label: '5', onTap: () => controller.rateReviewCard(lexemeId: card.lexeme.id, rating: 5)),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RateBtn extends StatelessWidget {
  final Color primary;
  final String label;
  final VoidCallback onTap;

  const _RateBtn({required this.primary, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary.withOpacity(0.25)),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w900, color: primary)),
      ),
    );
  }
}

class _WeakWordsSheet extends StatelessWidget {
  final Color primary;
  final VocabularyController controller;

  const _WeakWordsSheet({required this.primary, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(color: cs.outlineVariant.withOpacity(0.6), borderRadius: BorderRadius.circular(99)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text('Weak Words', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.onSurface)),
              ),
              IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close_rounded, color: cs.outline)),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.weakWords.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text('Chưa có dữ liệu.', style: TextStyle(color: cs.outline, fontWeight: FontWeight.w700)),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.weakWords.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final w = controller.weakWords[i];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: cs.surfaceContainerHighest.withOpacity(0.35),
                      border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: primary.withOpacity(0.14)),
                          child: Icon(Icons.warning_rounded, color: primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.lemma, style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface)),
                              const SizedBox(height: 4),
                              Text(
                                '${w.type} • ${w.severity} • ${w.errorType} • x${w.occurCount}',
                                style: TextStyle(color: cs.onSurface.withOpacity(0.7), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
