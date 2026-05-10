import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../shared/models/berkas_model.dart';

/// Keeps the Android home widget in sync with the latest berkas data.
class WidgetService {
  static const _qualifiedAndroidName = 'com.example.notecustomseasyuse.BerkasKuWidgetProvider';

  /// Must be called once on app startup before any widget operations.
  static Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId('com.example.notecustomseasyuse');
    } catch (_) {}
  }

  static Future<void> updateRecentBerkas(List<BerkasModel> allBerkas) async {
    try {
      final recent = allBerkas.take(3).toList();
      for (int i = 0; i < 3; i++) {
        final hasItem = i < recent.length;
        await HomeWidget.saveWidgetData<String>(
          'widget_recent_${i + 1}',
          hasItem ? recent[i].title : '',
        );
        await HomeWidget.saveWidgetData<String>(
          'widget_icon_${i + 1}',
          hasItem ? recent[i].iconName : '',
        );
      }
      await HomeWidget.saveWidgetData<int>('widget_total', allBerkas.length);
      await HomeWidget.updateWidget(
        androidName: 'BerkasKuWidgetProvider',
        qualifiedAndroidName: _qualifiedAndroidName,
      );
    } catch (_) {
      // Widget not placed on home screen or update failed — ignore silently.
    }
  }
}

/// Holds a pending deep-link action triggered by a home widget button tap.
/// Value is the URI host string, e.g. 'add_note' or 'open_list'.
final pendingWidgetActionProvider = StateProvider<String?>((ref) => null);
