/// Service locator / Dependency Injection setup
/// Optional - use if you prefer over providers
/// 
/// Example with GetIt:
/// ```dart
/// final getIt = GetIt.instance;
/// 
/// void setupLocator() {
///   getIt.registerSingleton<ApiClient>(ApiClient());
///   getIt.registerSingleton<SessionStorage>(SessionStorage());
/// }
/// ```
