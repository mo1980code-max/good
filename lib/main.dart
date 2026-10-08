import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/sound_helper.dart';
import 'data/repositories/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local storage and the audio pool are ready *before* the first frame,
  // so the Splash screen can already play its chime without a cold start.
  await LocalStorageService.instance.init();
  await SoundHelper.init();

  runApp(const ProviderScope(child: SparkleNailApp()));
}
