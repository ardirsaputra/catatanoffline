import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import '../../shared/models/berkas_model.dart';

/// Keeps the Android home widget in sync with the latest berkas data.
class WidgetService {
  static Future<void> updateRecentBerkas(List<BerkasModel> allBerkas) async {
    final recent = allBerkas.take(3).toList();
    for (int i = 0; i < 3; i++) {
      await HomeWidget.saveWidgetData<String>(
        'widget_recent_${i + 1}',
        i < recent.length ? recent[i].title : '',
      );
    }
    await HomeWidget.updateWidget(androidName: 'BerkasKuWidgetProvider');
  }
}

/// Holds a pending deep-link action triggered by a home widget button tap.
/// Value is the URI host string, e.g. 'add_note'.
final pendingWidgetActionProvider = StateProvider<String?>((ref) => null);
