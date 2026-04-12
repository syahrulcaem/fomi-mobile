import 'dart:typed_data';

import 'png_file_saver_stub.dart' if (dart.library.io) 'png_file_saver_io.dart';

Future<String?> savePngToLocal({
  required Uint8List bytes,
  required String fileName,
}) {
  return savePngToLocalImpl(bytes: bytes, fileName: fileName);
}
