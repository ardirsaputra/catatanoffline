import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'data/local/hive_service.dart';
import 'features/widget/widget_service.dart';
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

  runApp(
    UncontrolledProviderScope(
      container: _container,
      child: const BerkasKuApp(),
    ),
  );
}
