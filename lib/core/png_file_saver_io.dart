import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> savePngToLocalImpl({
  required Uint8List bytes,
  required String fileName,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final downloadDir =
      Directory('${directory.path}${Platform.pathSeparator}downloads');

  if (!downloadDir.existsSync()) {
    downloadDir.createSync(recursive: true);
  }

  final sanitizedName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final target =
      File('${downloadDir.path}${Platform.pathSeparator}$sanitizedName');
  await target.writeAsBytes(bytes, flush: true);
  return target.path;
}
