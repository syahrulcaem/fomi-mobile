import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> savePngToLocalImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  final sanitizedName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final result = await ImageGallerySaver.saveImage(
        bytes,
        quality: 100,
        name: sanitizedName,
        isReturnImagePathOfIOS: true,
      );

      if (result is Map) {
        final successValue = result['isSuccess'];
        final success =
            successValue == true || successValue?.toString() == 'true';
        final path = (result['filePath'] ?? result['path'])?.toString();
        if (success || (path != null && path.isNotEmpty)) {
          return (path != null && path.isNotEmpty) ? path : 'gallery';
        }
      }
    } catch (_) {
      // Fall back to app-local documents storage when gallery save is unavailable.
    }
  }

  final directory = await getApplicationDocumentsDirectory();
  final downloadDir =
      Directory('${directory.path}${Platform.pathSeparator}downloads');

  if (!downloadDir.existsSync()) {
    downloadDir.createSync(recursive: true);
  }

  final target =
      File('${downloadDir.path}${Platform.pathSeparator}$sanitizedName');
  await target.writeAsBytes(bytes, flush: true);
  return target.path;
}
