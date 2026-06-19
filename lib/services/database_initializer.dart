export 'database_initializer_stub.dart'
    if (dart.library.io) 'database_initializer_io.dart'
    if (dart.library.html) 'database_initializer_web.dart';
