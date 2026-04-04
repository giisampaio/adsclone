// Web: sem dart:io. VM/desktop/mobile: stub com dart:io.
export 'download_helper_web.dart'
    if (dart.library.io) 'download_helper_stub.dart';
