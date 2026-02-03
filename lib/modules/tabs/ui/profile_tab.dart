import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lingougo/core/network/api_client.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/notify/app_toast.dart';
import '../../../core/ui/neumorphic_card.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _dio = ApiClient.instance.dio;
  late final LocalAuthentication _localAuth;
  late final FlutterSecureStorage _storage;

  String userName = 'Loading...';
  String userEmail = 'Loading...';
  String userRole = 'student';
  List<String> userPermissions = [];
  
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  String? deviceId;
  String? deviceFingerprint;

  int speakingScore = 0;
  int currentStreak = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _localAuth = LocalAuthentication();
    _storage = const FlutterSecureStorage();
    _initProfile();
  }

  Future<void> _initProfile() async {
    try {
      // Check biometric availability
      final isBiometricAvailable = await _localAuth.canCheckBiometrics;
      
      setState(() {
        biometricAvailable = isBiometricAvailable;
      });

      // Check if biometric is already enabled
      final savedDeviceId = await _storage.read(key: 'device_id');
      final savedFingerprint = await _storage.read(key: 'device_fingerprint');
      if (savedDeviceId != null && savedFingerprint != null) {
        setState(() {
          biometricEnabled = true;
          deviceId = savedDeviceId;
          deviceFingerprint = savedFingerprint;
        });
      }

      // Load user data from /auth/me
      final userResponse = await _dio.get('/auth/me');
      if (userResponse.statusCode == 200) {
        final userData = userResponse.data['data'];
        setState(() {
          userName = userData['display_ name'] ?? 'User';
          userEmail = userData['email'] ?? '';
          userRole = userData['role'] ?? 'student';
          userPermissions = List<String>.from(userData['permissions'] ?? []);
          speakingScore = (userData['speaking_score'] ?? 0).toInt();
          currentStreak = (userData['streak'] ?? 0).toInt();
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Lỗi tải hồ sơ: ${e.toString()}',
          type: AppToastType.error,
        );
      }
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleBiometric() async {
    if (!biometricAvailable) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Thiết bị không hỗ trợ xác thực sinh trắc học',
          type: AppToastType.warning,
        );
      }
      return;
    }

    try {
      // Authenticate with biometrics
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực để bật đăng nhập sinh trắc học',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!isAuthenticated) return;

      // Generate device ID and fingerprint
      final newDeviceId = DateTime.now().millisecondsSinceEpoch.toString();
      final newFingerprint = _generateFingerprint();

      // Store in secure storage
      await _storage.write(key: 'device_id', value: newDeviceId);
      await _storage.write(key: 'device_fingerprint', value: newFingerprint);

      if (mounted) {
        setState(() {
          biometricEnabled = true;
          deviceId = newDeviceId;
          deviceFingerprint = newFingerprint;
        });

        AppToast.show(
          context,
          message: 'Đã bật xác thực sinh trắc học thành công',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Lỗi: ${e.toString()}',
          type: AppToastType.error,
        );
      }
    }
  }

  Future<void> _disableBiometric() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Xác thực để tắt đăng nhập sinh trắc học',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!isAuthenticated) return;

      await _storage.delete(key: 'device_id');
      await _storage.delete(key: 'device_fingerprint');

      if (mounted) {
        setState(() {
          biometricEnabled = false;
          deviceId = null;
          deviceFingerprint = null;
        });

        AppToast.show(
          context,
          message: 'Đã tắt xác thực sinh trắc học',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Lỗi: ${e.toString()}',
          type: AppToastType.error,
        );
      }
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                AuthState.instance.clear();
                context.go('/login');
                AppToast.show(
                  context,
                  message: 'Đã đăng xuất thành công',
                  type: AppToastType.success,
                );
              }
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  String _generateFingerprint() {
    // Simple fingerprint generation - in production, use device_info package
    return 'fp_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const purple = Color(0xFF6D28D9);
    const purple2 = Color(0xFF8B5CF6);

    return Scaffold(
      body: isLoading
          ? Center(child: const CircularProgressIndicator(color: purple))
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
                // Soft blobs
                const Positioned(top: -90, left: -70, child: _Blob(size: 240, color: Colors.white24)),
                const Positioned(bottom: -110, right: -80, child: _Blob(size: 300, color: Colors.white12)),
                
                CustomScrollView(
                  slivers: [
                    // Header
                    SliverAppBar(
                      expandedHeight: 0,
                      pinned: true,
                      elevation: 0,
                      backgroundColor: Colors.transparent,
                    ),
                    // User Info Section with Logout Button
                    SliverToBoxAdapter(
                      child: Container(
                        color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: NeumorphicCard(
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        color: Colors.white.withOpacity(0.04),
                        child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6D28D9), Color(0xFF8B5CF6)],
                              ),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_rounded,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Name and email
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Logout button
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _logout,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                        ),
                    ),
                  ),
                ),
                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Statistics
                      Text(
                        'Thống kê',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.mic_rounded,
                              label: 'Điểm nói',
                              value: '$speakingScore/100',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Streak',
                              value: '$currentStreak ngày',
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Settings
                      Text(
                        'Cài đặt',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Biometric
                      if (biometricAvailable)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: biometricEnabled
                                  ? _disableBiometric
                                  : _handleBiometric,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6D28D9).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.fingerprint_rounded,
                                        color: Color(0xFF6D28D9),
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Đăng nhập sinh trắc học',
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            biometricEnabled
                                                ? 'Đã bật'
                                                : 'Nhấn để bật',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: biometricEnabled,
                                      onChanged: (_) => biometricEnabled
                                          ? _disableBiometric()
                                          : _handleBiometric(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Teacher/Admin Section
                      if (userRole == 'teacher' || userRole == 'admin') ...[
                        Text(
                          'Công cụ quản lý',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _AdminActionButton(
                          icon: Icons.book_rounded,
                          label: 'Chỉnh sửa bài học',
                          onTap: () {},
                          color: Colors.blue,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _AdminActionButton(
                          icon: Icons.mic_rounded,
                          label: 'Chỉnh sửa bài nói',
                          onTap: () {},
                          color: Colors.orange,
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _AdminActionButton(
                          icon: Icons.folder_rounded,
                          label: 'Quản lý nội dung',
                          onTap: () {},
                          color: Colors.purple,
                          theme: theme,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeumorphicCard(
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(12),
      color: Colors.white.withOpacity(0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _AdminActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final ThemeData theme;

  const _AdminActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.5),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
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
