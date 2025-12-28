import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url:'https://zvtlmgipexhhtuvnvkey.supabase.co',
      anonKey:'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp2dGxtZ2lwZXhoaHR1dm52a2V5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4NDc0NjAsImV4cCI6MjA4MjQyMzQ2MH0.Db24ZzBNawSqMvxObeK9Ah4LrHvu4q4-RvybcPpLnWQ',
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}