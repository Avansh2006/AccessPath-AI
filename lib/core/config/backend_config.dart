class BackendConfig {
  const BackendConfig({
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory BackendConfig.fromEnvironment() => const BackendConfig(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String supabaseUrl;
  final String supabaseAnonKey;

  bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
