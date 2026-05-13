import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'data/local/hive_service.dart';
import 'features/widget/widget_service.dart';
import 'features/export/incoming_file_provider.dart';
import 'app/app.dart';

final _container = ProviderContainer();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await initializeDateFormatting('id_ID', null);
  await HiveService.init();

  // Initialise home widget (must be done before any widget operations).
  await WidgetService.init();

  // // Record first-launch time for trial
  // final authBox = Hive.box<String>('auth');
  // if (!authBox.containsKey('trial_start')) {
  //   await authBox.put('trial_start', DateTime.now().toIso8601String());
  // }

  // Handle cold-start launch from home widget
  final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  if (initialUri?.host != null) {
    _container.read(pendingWidgetActionProvider.notifier).state = initialUri!.host;
  }

  // Handle widget click when app is already in background
  HomeWidget.widgetClicked.listen((uri) {
    if (uri?.host != null) {
      _container.read(pendingWidgetActionProvider.notifier).state = uri!.host;
    }
  });

  // Handle .docx/.doc files opened via file manager or share sheet (cold start)
  bool isWordFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.docx') || lower.endsWith('.doc');
  }

  try {
    final initialFiles = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialFiles.isNotEmpty) {
      for (final f in initialFiles) {
        if (isWordFile(f.path)) {
          _container.read(incomingDocxPathProvider.notifier).state = f.path;
          break;
        }
      }
    }
  } catch (_) {}

  // Handle .docx/.doc files shared while app is already running
  ReceiveSharingIntent.instance.getMediaStream().listen((files) {
    try {
      for (final f in files) {
        if (isWordFile(f.path)) {
          _container.read(incomingDocxPathProvider.notifier).state = f.path;
          break;
        }
      }
    } catch (_) {}
  });

  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const BerkasKuApp(),
    ),
  );
}
