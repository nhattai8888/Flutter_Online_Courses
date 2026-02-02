import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_instance.dart';
import '../../../core/notify/app_toast.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late final DioInstance _dioInstance;
  
  String userName = 'Loading...';
  String userEmail = '';
  String userRole = 'student';
  List<String> userPermissions = [];
  String? currentLanguageId;

  int reviewToday = 0;
  int streak = 0;
  int masteredCount = 0;
  DateTime? lastReviewTime;

  String continueTitle = '';
  String continueLessonId = '';

  int speakingTasksCount = 0;
  int weakWordsCount = 0;
  List<Map<String, dynamic>> weakWords = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _dioInstance = DioInstance();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final userResponse = await _dioInstance.get('/auth/me');
      if (userResponse.statusCode == 200) {
        final userData = userResponse.data['data'];
        setState(() {
          userName = userData['display_name'] ?? 'User';
          userEmail = userData['email'] ?? '';
          userRole = userData['role'] ?? 'student';
          // Normalize permissions: server may return list of strings or objects
          final permsRaw = userData['permissions'] ?? [];
          final perms = <String>[];
          if (permsRaw is List) {
            for (final p in permsRaw) {
              if (p is String) {
                perms.add(p.toUpperCase());
              } else if (p is Map && p['code'] != null) {
                perms.add(p['code'].toString().toUpperCase());
              } else if (p is Map && p['name'] != null) {
                perms.add(p['name'].toString().toUpperCase());
              }
            }
          }
          userPermissions = perms;
          final langId = userData['current_language_id'] ?? userData['current_language']?['id'];
          currentLanguageId = langId?.toString();
        });
      }

      if (currentLanguageId != null && currentLanguageId!.isNotEmpty) {
        final statsResponse = await _dioInstance.get(
          '/review/stats',
          queryParameters: {'language_id': currentLanguageId},
        );
        if (statsResponse.statusCode == 200) {
          final stats = statsResponse.data['data'];
          setState(() {
            streak = stats['streak'] ?? 0;
            masteredCount = stats['mastered_count'] ?? 0;
            if (stats['last_review'] != null) {
              lastReviewTime = DateTime.parse(stats['last_review']);
            }
          });
        }

        final todayResponse = await _dioInstance.get(
          '/review/today',
          queryParameters: {
            'language_id': currentLanguageId,
            'limit': 20,
          },
        );
        if (todayResponse.statusCode == 200) {
          setState(() {
            reviewToday = todayResponse.data['data']?['length'] ?? 0;
          });
        }
      }

      // Only fetch weak words if user has permission, avoid 403
      if (userPermissions.contains('VOCAB_WEAK_WORDS')) {
        final weakWordsResponse = await _dioInstance.get(
          '/vocab/weak-words',
          queryParameters: {'limit': 50},
        );
        if (weakWordsResponse.statusCode == 200) {
          setState(() {
            weakWords = List<Map<String, dynamic>>.from(
              weakWordsResponse.data['data'] ?? [],
            );
            weakWordsCount = weakWords.length;
          });
        } else if (weakWordsResponse.statusCode == 403) {
          setState(() {
            weakWords = [];
            weakWordsCount = 0;
          });
        }
      } else {
        setState(() {
          weakWords = [];
          weakWordsCount = 0;
        });
      }

      // Use speaking tasks endpoint to determine available speaking activities
      final speakingQuery = <String, dynamic>{'limit': 50, 'offset': 0, 'task_type': 'all'};
      if (currentLanguageId == null || currentLanguageId!.isEmpty) {
        try {
          final langsResp = await _dioInstance.get('/languages', queryParameters: {'limit': 1});
          if (langsResp.statusCode == 200) {
            final list = langsResp.data['data'] as List?;
            if (list != null && list.isNotEmpty) {
              currentLanguageId = list.first['id']?.toString();
            }
          }
        } catch (_) {}
      }

      if (currentLanguageId != null && currentLanguageId!.isNotEmpty) {
        speakingQuery['language_id'] = currentLanguageId;
      }

      final speakingTasksResponse = await _dioInstance.get(
        '/speaking/tasks',
        queryParameters: speakingQuery,
      );
      if (speakingTasksResponse.statusCode == 200) {
        final items = speakingTasksResponse.data['data'] ?? [];
        setState(() {
          speakingTasksCount = (items as List).length;
        });
      } else if (speakingTasksResponse.statusCode == 403) {
        setState(() {
          speakingTasksCount = 0;
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Lỗi tải dữ liệu: ${e.toString()}',
          type: AppToastType.error,
        );
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D28D9);
    const purple2 = Color(0xFF8B5CF6);
    const accentOrange = Color(0xFFEA580C);
    const accentGreen = Color(0xFF16A34A);

    return Scaffold(
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: purple),
            )
          : Stack(
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
                // Decorative blobs
                const Positioned(top: -90, left: -70, child: _Blob(size: 240, color: Colors.white24)),
                const Positioned(bottom: -110, right: -80, child: _Blob(size: 300, color: Colors.white12)),
                
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 0,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // Welcome Header
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Xin chào! 👋',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          userName.split(' ').first,
                                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.2),
                                      border: Border.all(color: Colors.white, width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Today's Goals - Beautiful Card
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.98),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Hôm nay cần làm gì?',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEE2E2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.local_fire_department_rounded, 
                                                size: 16, color: Color(0xFFDC2626)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$streak ngày',
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: const Color(0xFFDC2626),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Progress Grid
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _GoalCard(
                                            icon: Icons.refresh_rounded,
                                            label: 'Ôn tập',
                                            value: '$reviewToday',
                                            color: const Color(0xFF3B82F6),
                                            onTap: () => context.go('/review'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _GoalCard(
                                            icon: Icons.mic_rounded,
                                            label: 'Nói',
                                            value: '$speakingTasksCount',
                                            color: accentOrange,
                                            onTap: () => context.go('/speaking'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Stats Section - Achievement Cards
                          Text(
                            'Tiến độ của bạn',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _AchievementCard(
                                  icon: Icons.check_circle_rounded,
                                  value: '$masteredCount',
                                  label: 'Nắm vững',
                                  color: accentGreen,
                                  bgColor: const Color(0xFFF0FDF4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _AchievementCard(
                                  icon: Icons.trending_up_rounded,
                                  value: '${(masteredCount * 5).clamp(0, 100)}%',
                                  label: 'Hoàn thành',
                                  color: const Color(0xFF8B5CF6),
                                  bgColor: const Color(0xFFF5F3FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Continue Learning - Large CTA
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.go('/curriculum'),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [accentOrange, Color(0xFFFB923C)],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentOrange.withOpacity(0.4),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Bắt đầu bài học',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Tiếp tục theo lộ trình',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Weak Words Alert
                          if (weakWordsCount > 0) ...[
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFFCD34D),
                                  width: 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: accentOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.warning_rounded,
                                      color: accentOrange,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$weakWordsCount từ vựng yếu',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Ôn lại để cải thiện',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilledButton(
                                    onPressed: () => context.go('/review'),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: accentOrange,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      'Ôn ngay',
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          const SizedBox(height: 16),
                        ]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color bgColor;

  const _AchievementCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}
