class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });
}

class AuthMe {
  final String userId;
  final String displayName;
  final List<String> roles;
  final List<String> permissions;

  const AuthMe({
    required this.userId,
    required this.displayName,
    required this.roles,
    required this.permissions,
  });
}

class OtpChallenge {
  final String otpId;

  const OtpChallenge({required this.otpId});
}

class AuthLoginResult {
  final AuthTokens? tokens;
  final OtpChallenge? challenge;

  const AuthLoginResult._({this.tokens, this.challenge});

  const AuthLoginResult.authed(AuthTokens tokens) : this._(tokens: tokens);

  const AuthLoginResult.requireOtp(OtpChallenge challenge) : this._(challenge: challenge);

  bool get isAuthed => tokens != null;
  bool get requiresOtp => challenge != null;
}

enum SocialProvider { google, apple, microsoft }

class RegisterEmailPayload {
  final String email;
  final String password;
  final String displayName;

  const RegisterEmailPayload({
    required this.email,
    required this.password,
    required this.displayName,
  });
}

class RegisterPhonePayload {
  final String phone;
  final String displayName;

  const RegisterPhonePayload({
    required this.phone,
    required this.displayName,
  });
}

class OtpVerifyPayload {
  final String otpId;
  final String code;
  final String deviceId;
  final bool trustDevice;

  const OtpVerifyPayload({
    required this.otpId,
    required this.code,
    required this.deviceId,
    required this.trustDevice,
  });
}
