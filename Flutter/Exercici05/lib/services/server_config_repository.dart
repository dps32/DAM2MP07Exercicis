import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:exercici05/models/server_config.dart';

class ServerConfigRepository {
  static const String _fileName = 'server_configs.json';

  Future<List<ServerConfig>> loadConfigs() async {
    final file = await _resolveConfigFile();
    if (!await file.exists()) {
      return <ServerConfig>[];
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return <ServerConfig>[];
    }

    final decoded = jsonDecode(content);
    return ServerConfig.listFromDynamic(decoded);
  }

  Future<void> saveConfigs(List<ServerConfig> configs) async {
    final file = await _resolveConfigFile();
    final encodedList = <Map<String, dynamic>>[];
    for (final config in configs) {
      encodedList.add(config.toJson());
    }

    final pretty = const JsonEncoder.withIndent('  ');
    await file.writeAsString(pretty.convert(encodedList));
  }

  Future<File> _resolveConfigFile() async {
    final folder = await getApplicationDocumentsDirectory();
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    final separator = Platform.pathSeparator;
    final path = '${folder.path}$separator$_fileName';
    return File(path);
  }
}
