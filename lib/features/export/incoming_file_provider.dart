import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the file path of a .docx/.doc file that was opened/shared into the app.
/// When non-null, [app.dart] navigates to [DocxReaderScreen].
final incomingDocxPathProvider = StateProvider<String?>((_) => null);
