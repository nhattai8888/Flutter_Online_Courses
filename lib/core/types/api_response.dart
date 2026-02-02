class ApiResponse<T> {
  final String status;
  final T data;
  final String? message;
  final dynamic error;

  ApiResponse({
    required this.status,
    required this.data,
    this.message,
    this.error,
  });
}

T unwrap<T>(ApiResponse<T> response) {
  if (response.status != 'success') {
    throw response.error;
  }
  return response.data;
}
