import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Web implementation of file download via Blob and AnchorElement
Future<bool> saveOrDownloadFile({
  required String content,
  required String fileName,
  required String mimeType,
}) async {
  try {
    final bytes = utf8.encode(content);
    final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName;

    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
    return true;
  } catch (_) {
    return false;
  }
}
