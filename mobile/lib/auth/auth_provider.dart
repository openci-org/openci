import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  @override
  Stream<Session?> build() {
    final supabase = Supabase.instance.client;
    return supabase.auth.onAuthStateChange.map((event) => event.session);
  }

  SupabaseClient getSupabaseClient() => Supabase.instance.client;

  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;
}
