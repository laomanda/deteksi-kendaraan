import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// IO implementation of file save (Desktop Save dialog or Mobile Share sheet)
Future<bool> saveOrDownloadFile({
  required String content,
  required String fileName,
  required String mimeType,
}) async {
  try {
    // 1. On desktop (Windows, macOS, Linux): Try getSaveLocation for native Save File dialog
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        final saveLocation = await getSaveLocation(suggestedName: fileName);
        if (saveLocation != null) {
          final file = File(saveLocation.path);
          await file.writeAsString(content);
          return true;
        }
        // User cancelled save dialog
        return false;
      } catch (_) {
        // Fallback to temp file + share
      }
    }

    // 2. On Mobile (or desktop fallback): Save to temporary directory and invoke Share Sheet
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(content);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: fileName,
      text: 'Berkas cadangan data RideCare.',
    );
    return true;
  } catch (_) {
    return false;
  }
}
