import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/services/supabase_client.dart';
import 'presentation/app.dart';
import 'core/error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandler.init();
  await Supa.init();
  runApp(const ProviderScope(child: App()));
}
