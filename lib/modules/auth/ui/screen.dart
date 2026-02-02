import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'controller.dart';
import '../data/api.dart';
import '../data/repository_impl.dart';
import '../domain/usecases.dart';
import '../../../core/notify/app_toast.dart';

class AuthScreen extends StatefulWidget {
  final AuthController? controller;

  const AuthScreen({super.key, this.controller});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthController controller;

  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  final _otpCode = TextEditingController();

  bool _trustDevice = false;

  String? _lastInfo;
  String? _lastError;

  @override
  void initState() {
    super.initState();

    final repo = AuthRepositoryImpl(AuthApi());
    controller =
        widget.controller ??
        AuthController(
          loginEmailStartUseCase: LoginEmailStartUseCase(repo),
          loginPhoneStartUseCase: LoginPhoneStartUseCase(repo),
          verifyOtpUseCase: VerifyOtpUseCase(repo),
          getMeUseCase: GetMeUseCase(repo),
          registerPhoneUseCase: RegisterPhoneUseCase(repo),
          registerEmailUseCase: RegisterEmailUseCase(repo),
          forgotPasswordUseCase: ForgotPasswordUseCase(repo),
        );

    _identifier.addListener(_rebuild);
    _password.addListener(_rebuild);
    _displayName.addListener(_rebuild);
    _otpCode.addListener(_rebuild);

    // ✅ Listen controller để bắn toast — KHÔNG bắn trong build
    controller.addListener(_onControllerChanged);
  }

  void _rebuild() => setState(() {});

  void _onControllerChanged() {
    if (!mounted) return;

    final info = controller.info;
    final error = controller.error;

    if (info != null && info != _lastInfo) {
      _lastInfo = info;
      AppToast.show(context, message: info, type: AppToastType.info);
    }

    if (error != null && error != _lastError) {
      _lastError = error;
      AppToast.show(context, message: error, type: AppToastType.error);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);

    _identifier.removeListener(_rebuild);
    _password.removeListener(_rebuild);
    _displayName.removeListener(_rebuild);
    _otpCode.removeListener(_rebuild);

    _identifier.dispose();
    _password.dispose();
    _displayName.dispose();
    _otpCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    controller.clearBanners();

    if (controller.step == AuthStep.otp) {
      await controller.submitOtp(
        code: _otpCode.text,
        trustDevice: _trustDevice,
      );

      if (!mounted) return;

      AppToast.show(
        context,
        message: controller.loading
            ? 'Gửi OTP đến ${_identifier.text} thành công!'
            : 'Gửi OTP thất bại!',
        type: controller.loading ? AppToastType.success : AppToastType.error,
      );

      if (controller.otpVerifiedSuccessfully) {
        context.go('/curriculum');
      }
      return;
    }

    if (controller.mode == AuthMode.login) {
      await controller.submitLogin(
        identifier: _identifier.text,
        password: _password.text,
      );

      if (!mounted) return;

      AppToast.show(
        context,
        message: controller.loading
            ? 'Đăng nhập thành công!'
            : 'Đăng nhập thất bại!',
        type: controller.loading ? AppToastType.success : AppToastType.error,
      );
      return;
    }

    if (controller.mode == AuthMode.register) {
      await controller.submitRegister(
        identifier: _identifier.text,
        password: _password.text,
        displayName: _displayName.text,
      );

      if (!mounted) return;

      AppToast.show(
        context,
        message: controller.loading
            ? 'Đăng kí thành công!'
            : 'Đăng kí thất bại!',
        type: controller.loading ? AppToastType.success : AppToastType.error,
      );
      return;
    }
  }

  Future<void> _biometricLogin() async {
    if (!mounted) return;
    AppToast.show(
      context,
      message: 'Đăng nhập vân tay: sắp có (UI đã gắn).',
      type: AppToastType.info,
    );
  }

  bool get _canSubmit {
    if (controller.loading) return false;

    if (controller.step == AuthStep.otp) {
      return _otpCode.text.trim().length >= 4;
    }

    final err = controller.validateCredential(
      identifier: _identifier.text,
      password: _password.text,
      displayName: controller.mode == AuthMode.register
          ? _displayName.text
          : '',
    );
    return err == null;
  }

  @override
  Widget build(BuildContext context) {
    // Palette
    const purple = Color(0xFF6D28D9);
    const purple2 = Color(0xFF8B5CF6);
    const soft = Color(0xFFF5F3FF);

    return Scaffold(
      body: Stack(
        children: [
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
          const Positioned(
            top: -80,
            left: -60,
            child: _Blob(size: 220, color: Colors.white24),
          ),
          const Positioned(
            bottom: -90,
            right: -70,
            child: _Blob(size: 260, color: Colors.white12),
          ),

          SafeArea(
            child: AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final isOtp = controller.step == AuthStep.otp;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            const _AppMark(),
                            const SizedBox(height: 18),

                            _GlassCard(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    if (!isOtp) ...[
                                      _Segment(
                                        leftText: 'Đăng nhập',
                                        rightText: 'Đăng ký',
                                        isLeftSelected:
                                            controller.mode == AuthMode.login,
                                        onLeft: () =>
                                            controller.setMode(AuthMode.login),
                                        onRight: () => controller.setMode(
                                          AuthMode.register,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],

                                    if (!isOtp) ...[
                                      TextField(
                                        key: const ValueKey('auth.identifier'),
                                        controller: _identifier,
                                        decoration: _inputDeco(
                                          'Email hoặc SĐT',
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      const SizedBox(height: 12),

                                      if (controller.mode ==
                                          AuthMode.register) ...[
                                        TextField(
                                          key: const ValueKey(
                                            'auth.displayName',
                                          ),
                                          controller: _displayName,
                                          decoration: _inputDeco(
                                            'Tên hiển thị',
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                      ],

                                      TextField(
                                        key: const ValueKey('auth.password'),
                                        controller: _password,
                                        decoration: _inputDeco(
                                          'Mật khẩu (chỉ email)',
                                        ),
                                        obscureText: true,
                                      ),

                                      if (controller.mode ==
                                          AuthMode.login) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            TextButton(
                                              key: const ValueKey(
                                                'auth.forgotPassword',
                                              ),
                                              onPressed: controller.loading
                                                  ? null
                                                  : () => controller
                                                        .forgotPassword(
                                                          _identifier.text,
                                                        ),
                                              child: const Text(
                                                'Quên mật khẩu?',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: soft,
                                                ),
                                              ),
                                            ),
                                            const Spacer(),
                                            SizedBox(
                                              height: 48,
                                              width: 48,
                                              child: OutlinedButton(
                                                key: const ValueKey(
                                                  'auth.fingerprint',
                                                ),
                                                onPressed: controller.loading
                                                    ? null
                                                    : _biometricLogin,
                                                style: OutlinedButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: const Size(
                                                    48,
                                                    48,
                                                  ),
                                                  alignment: Alignment.center,
                                                  foregroundColor:
                                                      const Color.fromARGB(
                                                        255,
                                                        239,
                                                        245,
                                                        244,
                                                      ),
                                                  side: const BorderSide(
                                                    color: Color.fromARGB(
                                                      179,
                                                      255,
                                                      255,
                                                      255,
                                                    ),
                                                    width: 1.2,
                                                  ),
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.10),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.fingerprint_rounded,
                                                  size: 22,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: FilledButton(
                                            key: const ValueKey('auth.submit'),
                                            onPressed: _canSubmit
                                                ? _submit
                                                : null,
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                    255,
                                                    115,
                                                    89,
                                                    231,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: controller.loading
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Đăng nhập',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: FilledButton(
                                            key: const ValueKey('auth.submit'),
                                            onPressed: _canSubmit
                                                ? _submit
                                                : null,
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  const Color.fromARGB(
                                                    179,
                                                    131,
                                                    72,
                                                    233,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: controller.loading
                                                ? const SizedBox(
                                                    width: 22,
                                                    height: 22,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Đăng ký',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ] else ...[
                                      Row(
                                        children: const [
                                          Icon(
                                            Icons.verified_user_rounded,
                                            color: Color.fromARGB(255, 16, 227, 97),
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Xác minh OTP',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: Colors.white
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      TextField(
                                        key: const ValueKey('auth.otpCode'),
                                        controller: _otpCode,
                                        decoration: _inputDeco('Mã OTP'),
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 12),

                                      SwitchListTile.adaptive(
                                        value: _trustDevice,
                                        onChanged: controller.loading
                                            ? null
                                            : (v) => setState(
                                                () => _trustDevice = v,
                                              ),
                                        title: const Text(
                                          'Tin cậy thiết bị này',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white
                                          ),
                                        ),
                                        subtitle: const Text(
                                          'Chỉ bật nếu bạn muốn tránh OTP lần sau trên máy này',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        activeColor: Color(soft.value),
                                      ),
                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          TextButton.icon(
                                            onPressed: controller.loading
                                                ? null
                                                : () => controller.setMode(
                                                    controller.mode,
                                                  ),
                                            icon: const Icon(
                                              Icons.arrow_back_rounded,
                                              color: soft,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            label: const Text('Quay lại', style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color.fromARGB(255, 252, 252, 252)
                                            ),),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            key: const ValueKey(
                                              'auth.resendOtp',
                                            ),
                                            onPressed: controller.loading
                                                ? null
                                                : controller.resendOtp,
                                            child: const Text('Gửi lại OTP', style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color: Color.fromARGB(255, 252, 252, 252)
                                            ),),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: FilledButton(
                                          key: const ValueKey('auth.submit'),
                                          onPressed: _canSubmit
                                              ? _submit
                                              : null,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color.fromARGB(255, 144, 0, 255),
                                            shadowColor: purple,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                        
                                          ),
                                          child: controller.loading
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                )
                                              : const Text(
                                                  'Xác minh OTP',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Color.fromARGB(255, 255, 255, 255)
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Card(
                              elevation: 0,
                              color: soft.withOpacity(0.95),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  14,
                                ),
                                child: Column(
                                  children: [
                                    const _DividerText(
                                      text: 'Hoặc tiếp tục với',
                                    ),
                                    const SizedBox(height: 12),

                                    _SocialFilledButton(
                                      keyValue: 'auth.google',
                                      text: 'Tiếp tục với Google',
                                      icon: Icons.g_mobiledata_rounded,
                                      bg: const Color(0xFFFFF1F1),
                                      border: const Color(0xFFFCA5A5),
                                      iconColor: const Color(0xFFDB4437),
                                      onPressed: controller.loading
                                          ? null
                                          : () => controller.socialLogin(
                                              SocialProvider.google,
                                            ),
                                    ),
                                    const SizedBox(height: 10),

                                    _SocialFilledButton(
                                      keyValue: 'auth.apple',
                                      text: 'Tiếp tục với Apple',
                                      icon: Icons.apple_rounded,
                                      bg: Colors.white,
                                      border: const Color(0xFFE5E7EB),
                                      iconColor: const Color(0xFF111111),
                                      onPressed: controller.loading
                                          ? null
                                          : () => controller.socialLogin(
                                              SocialProvider.apple,
                                            ),
                                    ),
                                    const SizedBox(height: 10),

                                    _SocialFilledButton(
                                      keyValue: 'auth.microsoft',
                                      text: 'Tiếp tục với Microsoft',
                                      icon: Icons.window_rounded,
                                      bg: const Color(0xFFEFF6FF),
                                      border: const Color(0xFF93C5FD),
                                      iconColor: const Color(0xFF0078D4),
                                      onPressed: controller.loading
                                          ? null
                                          : () => controller.socialLogin(
                                              SocialProvider.microsoft,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),
                          ],
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

InputDecoration _inputDeco(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white.withOpacity(0.92),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

class _AppMark extends StatelessWidget {
  const _AppMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'LingouGO',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 0.6,
          ),
        ),
        SizedBox(height: 6),
      ],
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

class _SocialFilledButton extends StatelessWidget {
  final String keyValue;
  final String text;
  final IconData icon;
  final Color bg;
  final Color border;
  final Color iconColor;
  final VoidCallback? onPressed;

  const _SocialFilledButton({
    required this.keyValue,
    required this.text,
    required this.icon,
    required this.bg,
    required this.border,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton.icon(
        key: ValueKey(keyValue),
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: const Color(0xFF111827),
          side: BorderSide(color: border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  final String text;
  const _DividerText({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).dividerColor;
    return Row(
      children: [
        Expanded(child: Divider(color: c)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            text,
            style: TextStyle(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.70),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(child: Divider(color: c)),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String leftText;
  final String rightText;
  final bool isLeftSelected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const _Segment({
    required this.leftText,
    required this.rightText,
    required this.isLeftSelected,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.50)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _SegBtn(
              text: leftText,
              selected: isLeftSelected,
              onTap: onLeft,
            ),
          ),
          Expanded(
            child: _SegBtn(
              text: rightText,
              selected: !isLeftSelected,
              onTap: onRight,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SegBtn({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6D28D9);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? purple : Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
