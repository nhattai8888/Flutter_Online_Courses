class AppError {
  final String code;
  final String message;
  final int? status;
  final dynamic raw;

  AppError({
    required this.code,
    required this.message,
    this.status,
    this.raw,
  });
}
