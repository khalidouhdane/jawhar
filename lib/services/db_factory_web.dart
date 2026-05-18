import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory get webDatabaseFactory => createDatabaseFactoryFfiWeb(
  options: SqfliteFfiWebOptions(
    sharedWorkerUri: Uri.parse('/sqflite_sw.js'),
    sqlite3WasmUri: Uri.parse('/sqlite3.wasm'),
  ),
);
