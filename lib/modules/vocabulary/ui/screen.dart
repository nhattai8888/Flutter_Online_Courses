import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    const purple1 = Color(0xFF6D28D9);
    const purple2 = Color(0xFF8B5CF6);

    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final status = controller.status;

                return Column(
                  children: [
                    _TopBar(
                      title: widget.lessonId != null ? 'Từ vựng theo Lesson' : 'Chi tiết Lexeme',
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        child: _Body(status: status, controller: controller),
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

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final VocabularyStatus status;
  final VocabularyController controller;

  const _Body({required this.status, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (status == VocabularyStatus.loading) {
      return const Center(
        child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }

    if (status == VocabularyStatus.error) {
      return _Card(
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.error ?? 'Error',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    final lexemes = controller.lexemes;
    final selected = controller.selectedLexeme;

    return Row(
      children: [
        if (lexemes.isNotEmpty) ...[
          Expanded(
            flex: 4,
            child: _Card(
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
                      l.type.name.toUpperCase(),
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
          child: _LexemeDetail(controller: controller),
        ),
      ],
    );
  }
}

class _LexemeDetail extends StatelessWidget {
  final VocabularyController controller;
  const _LexemeDetail({required this.controller});

  @override
  Widget build(BuildContext context) {
    final l = controller.selectedLexeme;
    if (l == null) {
      return const _Card(
        child: Center(
          child: Text('Chọn 1 lexeme để xem chi tiết', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ),
      );
    }

    return _Card(
      child: ListView(
        children: [
          Text(l.lemma, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 6),
          Row(
            children: [
              _Pill(text: l.type.name.toUpperCase()),
              const SizedBox(width: 8),
              _Pill(text: 'Lv ${l.difficulty}'),
              if ((l.phoenic ?? '').isNotEmpty) ...[
                const SizedBox(width: 8),
                _Pill(text: l.phoenic!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Text('Senses', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),

          if (controller.senses.isEmpty)
            Text('Chưa có sense', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700))
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
                          'Domain: ${s.domain}',
                          style: TextStyle(color: Colors.white.withOpacity(0.86), fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        if (expanded) ...[
                          const SizedBox(height: 10),
                          const Text('Examples', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          if (controller.examples.isEmpty)
                            Text('Loading/No examples...', style: TextStyle(color: Colors.white.withOpacity(0.85))),
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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

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
