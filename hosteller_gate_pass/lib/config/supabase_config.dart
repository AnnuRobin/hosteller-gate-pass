import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // IMPORTANT: This file is gitignored - it won't be committed to GitHub
  // Replace these with your actual Supabase credentials
  
  static const String supabaseUrl = 'https://wcushctxrejdgbvqeiyw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndjdXNoY3R4cmVqZGdidnFlaXl3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY5NzgxOTgsImV4cCI6MjA4MjU1NDE5OH0.n_t5mGqInOY1HV9OsCS4yi7cQnMXtytG-BVFmCGucyM';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
}