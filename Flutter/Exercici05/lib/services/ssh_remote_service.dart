import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive_io.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:exercici05/models/disk_tree_node.dart';
import 'package:exercici05/models/remote_entry.dart';
import 'package:exercici05/models/server_config.dart';
import 'package:exercici05/models/server_runtime.dart';

class RemoteCommandResult {
  const RemoteCommandResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
  });

  final String stdout;
  final String stderr;
  final int exitCode;

  bool get isSuccess => exitCode == 0;
}

class SshRemoteService {
  SSHClient? _client;
  SftpClient? _sftp;
  ServerConfig? _connectedConfig;

  bool get isConnected => _client != null && _sftp != null;
  ServerConfig? get connectedConfig => _connectedConfig;

  Future<void> connect(ServerConfig config) async {
    await disconnect();

    final socket = await SSHSocket.connect(
      config.host,
      config.port,
      timeout: const Duration(seconds: 10),
    );

    List<SSHKeyPair>? identities;
    final keyPath = config.privateKeyPath.trim();
    if (keyPath.isNotEmpty) {
      final keyContent = await File(keyPath).readAsString();
      final passphrase = config.privateKeyPassphrase.trim();
      if (passphrase.isEmpty) {
        identities = SSHKeyPair.fromPem(keyContent);
      } else {
        identities = SSHKeyPair.fromPem(keyContent, passphrase);
      }
    }

    final client = SSHClient(
      socket,
      username: config.username,
      identities: identities,
      onPasswordRequest: () async {
        if (config.password.trim().isEmpty) {
          return null;
        }
        return config.password;
      },
    );

    try {
      await client.authenticated;
      final sftp = await client.sftp();
      _client = client;
      _sftp = sftp;
      _connectedConfig = config;
    } catch (_) {
      client.close();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    _sftp?.close();
    _sftp = null;

    _client?.close();
    _client = null;
    _connectedConfig = null;
  }

  Future<RemoteCommandResult> runCommand(String command) async {
    final client = _requireClient();
    final result = await client.runWithResult(command);
    return RemoteCommandResult(
      stdout: utf8.decode(result.stdout, allowMalformed: true),
      stderr: utf8.decode(result.stderr, allowMalformed: true),
      exitCode: result.exitCode ?? -1,
    );
  }





  Future<RemoteCommandResult> runCheckedCommand(String command) async {
    final result = await runCommand(command);
    if (result.isSuccess) {
      return result;
    }
    final message = StringBuffer();
    message.write('El comando ha fallado: $command');
    if (result.stderr.trim().isNotEmpty) {
      message.write('\n${result.stderr.trim()}');
    } else if (result.stdout.trim().isNotEmpty) {
      message.write('\n${result.stdout.trim()}');
    }
    throw Exception(message.toString());
  }

  Future<List<RemoteEntry>> listDirectory(String remotePath) async {
    final sftp = _requireSftp();
    final cleanPath = _normalizeRemotePath(remotePath);
    final items = await sftp.listdir(cleanPath);
    final entries = <RemoteEntry>[];

    for (final item in items) {
      if (item.filename == '.' || item.filename == '..') {
        continue;
      }

      final modeValue = item.attr.mode?.value;
      entries.add(
        RemoteEntry(
          name: item.filename,
          path: _joinRemotePath(cleanPath, item.filename),
          isDirectory: item.attr.isDirectory,
          size: item.attr.size,
          permissions: _formatMode(modeValue),
          userId: item.attr.userID,
          groupId: item.attr.groupID,
          modifiedAt: _readModifyDate(item.attr.modifyTime),
        ),
      );
    }

    entries.sort((a, b) {
      if (a.isDirectory && !b.isDirectory) {
        return -1;
      }
      if (!a.isDirectory && b.isDirectory) {
        return 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return entries;
  }





  Future<String> renameEntry(RemoteEntry entry, String newName) async {
    final sftp = _requireSftp();
    final cleanName = newName.trim();
    if (cleanName.isEmpty) {
      throw Exception('El nuevo nombre no puede estar vacio');
    }

    final parent = _parentRemotePath(entry.path);
    final newPath = _joinRemotePath(parent, cleanName);
    await sftp.rename(entry.path, newPath);
    return newPath;
  }

  Future<void> deleteEntry(RemoteEntry entry) async {
    final sftp = _requireSftp();
    if (entry.isDirectory) {
      await runCheckedCommand('rm -rf ${_shellQuote(entry.path)}');
      return;
    }
    await sftp.remove(entry.path);
  }




  Future<String> downloadEntry(
    RemoteEntry entry,
    String localFolderPath,
  ) async {
    final localFolder = Directory(localFolderPath);
    if (!await localFolder.exists()) {
      await localFolder.create(recursive: true);
    }

    if (entry.isDirectory) {
      final remoteArchive =
          '/tmp/${entry.name}_${DateTime.now().millisecondsSinceEpoch}.tar.gz';
      final parent = _parentRemotePath(entry.path);
      await runCheckedCommand(
        'tar -czf ${_shellQuote(remoteArchive)} -C ${_shellQuote(parent)} ${_shellQuote(entry.name)}',
      );

      final localArchivePath = _joinLocalPath(
        localFolderPath,
        '${entry.name}.tar.gz',
      );
      try {
        await _downloadRemoteFile(remoteArchive, localArchivePath);
      } finally {
        await runCommand('rm -f ${_shellQuote(remoteArchive)}');
      }
      return localArchivePath;
    }

    final localFilePath = _joinLocalPath(localFolderPath, entry.name);
    await _downloadRemoteFile(entry.path, localFilePath);
    return localFilePath;
  }




  Future<void> _downloadRemoteFile(
    String remoteFilePath,
    String localFilePath,
  ) async {
    final sftp = _requireSftp();
    final remoteFile = await sftp.open(
      remoteFilePath,
      mode: SftpFileOpenMode.read,
    );
    final sink = File(localFilePath).openWrite();
    try {
      await remoteFile.downloadTo(sink, closeDestination: true);
    } finally {
      await remoteFile.close();
    }
  }



  Future<String> uploadLocalFile(
    String localFilePath,
    String remoteDirectory,
  ) async {
    final sftp = _requireSftp();
    final localFile = File(localFilePath);
    if (!await localFile.exists()) {
      throw Exception('No se encuentra el archivo local: $localFilePath');
    }

    final fileName = _nameFromAnyPath(localFilePath);
    final remoteFilePath = _joinRemotePath(remoteDirectory, fileName);
    final remoteFile = await sftp.open(
      remoteFilePath,
      mode:
          SftpFileOpenMode.create |
          SftpFileOpenMode.write |
          SftpFileOpenMode.truncate,
    );

    try {
      final content = await localFile.readAsBytes();
      await remoteFile.writeBytes(Uint8List.fromList(content));
    } finally {
      await remoteFile.close();
    }
    return remoteFilePath;
  }



  Future<String> uploadLocalDirectoryAsZip(
    String localDirectoryPath,
    String remoteDirectory,
  ) async {
    final localDirectory = Directory(localDirectoryPath);
    if (!await localDirectory.exists()) {
      throw Exception('No se encuentra la carpeta local: $localDirectoryPath');
    }

    final tempRoot = await Directory.systemTemp.createTemp('ssh_upload_zip_');
    final zipName = '${_nameFromAnyPath(localDirectoryPath)}.zip';
    final zipPath = _joinLocalPath(tempRoot.path, zipName);

    try {
      final zipEncoder = ZipFileEncoder();
      await zipEncoder.zipDirectory(
        localDirectory,
        filename: zipPath,
        level: ZipFileEncoder.gzip,
      );

      final remoteZipPath = await uploadLocalFile(zipPath, remoteDirectory);
      await runCheckedCommand(
        'unzip -o ${_shellQuote(remoteZipPath)} -d ${_shellQuote(remoteDirectory)} && rm -f ${_shellQuote(remoteZipPath)}',
      );
      return remoteZipPath;
    } finally {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    }
  }

  

  Future<void> extractRemoteZip(
    String remoteZipPath,
    String remoteDirectory,
  ) async {
    await runCheckedCommand(
      'unzip -o ${_shellQuote(remoteZipPath)} -d ${_shellQuote(remoteDirectory)}',
    );
  }

  Future<String> getEntryInfo(RemoteEntry entry) async {
    final command = 'stat ${_shellQuote(entry.path)}';
    final result = await runCommand(command);
    if (result.isSuccess && result.stdout.trim().isNotEmpty) {
      return result.stdout.trim();
    }

    final buffer = StringBuffer();
    buffer.writeln('Nombre: ${entry.name}');
    buffer.writeln('Ruta: ${entry.path}');
    buffer.writeln('Permisos: ${entry.permissions}');
    buffer.writeln('ID usuario: ${entry.userId ?? '-'}');
    buffer.writeln('ID grupo: ${entry.groupId ?? '-'}');
    buffer.writeln('Tamano: ${entry.size ?? '-'}');
    return buffer.toString().trim();
  }

  Future<ServerRuntimeType> detectRuntimeType(String projectPath) async {
    final cleanPath = _normalizeRemotePath(projectPath);
    final packageJson = _joinRemotePath(cleanPath, 'package.json');
    final pomFile = _joinRemotePath(cleanPath, 'pom.xml');
    final gradleFile = _joinRemotePath(cleanPath, 'build.gradle');
    final gradleKtsFile = _joinRemotePath(cleanPath, 'build.gradle.kts');

    final command =
        '''
if [ -f ${_shellQuote(packageJson)} ]; then
  echo node
elif [ -f ${_shellQuote(pomFile)} ] || [ -f ${_shellQuote(gradleFile)} ] || [ -f ${_shellQuote(gradleKtsFile)} ]; then
  echo java
else
  echo unknown
fi
''';

    final result = await runCheckedCommand(command);
    final label = result.stdout.trim();
    if (label == 'node') {
      return ServerRuntimeType.node;
    }
    if (label == 'java') {
      return ServerRuntimeType.java;
    }
    return ServerRuntimeType.unknown;
  }

  Future<ServerRuntimeState> getRuntimeState(
    String projectPath,
    ServerRuntimeType type,
  ) async {
    if (type == ServerRuntimeType.unknown) {
      return ServerRuntimeState.error;
    }

    final pattern = _runtimePattern(type, projectPath);
    final command =
        '''
if pgrep -f ${_shellQuote(pattern)} >/dev/null; then
  echo running
else
  echo stopped
fi
''';

    final result = await runCheckedCommand(command);
    final text = result.stdout.trim();
    if (text == 'running') {
      return ServerRuntimeState.running;
    }
    return ServerRuntimeState.stopped;
  }

  Future<void> startRuntime(String projectPath, ServerRuntimeType type) async {
    final command = _startRuntimeCommand(projectPath, type);
    await runCheckedCommand(command);
  }

  Future<void> stopRuntime(String projectPath, ServerRuntimeType type) async {
    final pattern = _runtimePattern(type, projectPath);
    await runCheckedCommand('pkill -f ${_shellQuote(pattern)} || true');
  }

  Future<void> restartRuntime(
    String projectPath,
    ServerRuntimeType type,
  ) async {
    await stopRuntime(projectPath, type);
    await Future<void>.delayed(const Duration(seconds: 1));
    await startRuntime(projectPath, type);
  }

  Future<int?> getForwardedPort80() async {
    final result = await runCommand(
      "sudo iptables -t nat -S PREROUTING | grep -- '--dport 80' | head -n 1",
    );
    if (result.stdout.trim().isEmpty) {
      return null;
    }

    final match = RegExp(r'--to-ports\s+(\d+)').firstMatch(result.stdout);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  Future<void> enablePortForward80(int targetPort) async {
    await runCommand(
      'sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports $targetPort >/dev/null 2>&1 || true',
    );
    await runCheckedCommand(
      'sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports $targetPort',
    );
  }

  Future<void> disablePortForward80(int targetPort) async {
    await runCheckedCommand(
      'sudo iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports $targetPort || true',
    );
  }

  Future<DiskTreeNode> loadDiskTree(String rootPath) async {
    final cleanRoot = _normalizeRemotePath(rootPath);
    final result = await runCommand(
      'du -b --max-depth=2 ${_shellQuote(cleanRoot)} 2>/dev/null || true',
    );

    final sizeByPath = <String, int>{};
    final lines = result.stdout.split('\n');
    final parser = RegExp(r'^(\d+)\s+(.+)$');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final match = parser.firstMatch(trimmed);
      if (match == null) {
        continue;
      }
      final size = int.tryParse(match.group(1) ?? '');
      final path = match.group(2);
      if (size == null || path == null) {
        continue;
      }
      sizeByPath[_normalizeRemotePath(path)] = size;
    }

    if (!sizeByPath.containsKey(cleanRoot)) {
      final rootStat = await runCommand(
        'du -sb ${_shellQuote(cleanRoot)} 2>/dev/null | cut -f1',
      );
      final parsed = int.tryParse(rootStat.stdout.trim());
      sizeByPath[cleanRoot] = parsed ?? 0;
    }

    final nodes = <String, DiskTreeNode>{};
    DiskTreeNode ensureNode(String path) {
      final normalized = _normalizeRemotePath(path);
      final existing = nodes[normalized];
      if (existing != null) {
        return existing;
      }

      final node = DiskTreeNode(
        name: _nameFromAnyPath(normalized),
        path: normalized,
        size: sizeByPath[normalized] ?? 0,
      );
      nodes[normalized] = node;

      if (normalized != cleanRoot) {
        final parentPath = _parentRemotePath(normalized);
        final parent = ensureNode(parentPath);
        var found = false;
        for (final child in parent.children) {
          if (child.path == normalized) {
            found = true;
            break;
          }
        }
        if (!found) {
          parent.children.add(node);
        }
      }
      return node;
    }

    final paths = <String>[];
    for (final path in sizeByPath.keys) {
      paths.add(path);
    }
    for (final path in paths) {
      ensureNode(path);
    }

    final rootNode = ensureNode(cleanRoot);
    _sortDiskTree(rootNode);
    return rootNode;
  }

  void _sortDiskTree(DiskTreeNode node) {
    node.children.sort((a, b) => b.size.compareTo(a.size));
    for (final child in node.children) {
      _sortDiskTree(child);
    }
  }

  String _startRuntimeCommand(String projectPath, ServerRuntimeType type) {
    final cleanPath = _normalizeRemotePath(projectPath);
    if (type == ServerRuntimeType.node) {
      return 'cd ${_shellQuote(cleanPath)} && nohup npm start > manager.log 2>&1 &';
    }
    if (type == ServerRuntimeType.java) {
      return "cd ${_shellQuote(cleanPath)} && nohup sh -c 'if [ -f ./mvnw ]; then ./mvnw spring-boot:run; elif [ -f ./gradlew ]; then ./gradlew bootRun; else JAR=\$(ls *.jar 2>/dev/null | head -n 1); if [ -n \"\$JAR\" ]; then java -jar \"\$JAR\"; else echo no-jar-found; exit 1; fi; fi' > manager.log 2>&1 &";
    }
    throw Exception('Tipo de runtime desconocido');
  }

  String _runtimePattern(ServerRuntimeType type, String projectPath) {
    final cleanPath = _normalizeRemotePath(projectPath);
    if (type == ServerRuntimeType.node) {
      return 'node.*$cleanPath';
    }
    if (type == ServerRuntimeType.java) {
      return 'java.*$cleanPath';
    }
    return cleanPath;
  }

  String _formatMode(int? modeValue) {
    if (modeValue == null) {
      return '-';
    }
    return modeValue.toRadixString(8).padLeft(4, '0');
  }

  DateTime? _readModifyDate(int? modifyTimeSeconds) {
    if (modifyTimeSeconds == null) {
      return null;
    }
    final milliseconds = modifyTimeSeconds * 1000;
    return DateTime.fromMillisecondsSinceEpoch(
      milliseconds,
      isUtc: true,
    ).toLocal();
  }

  SSHClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw Exception('Cliente SSH no conectado');
    }
    return client;
  }

  SftpClient _requireSftp() {
    final sftp = _sftp;
    if (sftp == null) {
      throw Exception('Cliente SFTP no conectado');
    }
    return sftp;
  }

  String _normalizeRemotePath(String path) {
    var value = path.trim();
    if (value.isEmpty) {
      return '/';
    }
    value = value.replaceAll('\\', '/');
    while (value.contains('//')) {
      value = value.replaceAll('//', '/');
    }
    if (value.length > 1 && value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (!value.startsWith('/')) {
      value = '/$value';
    }
    return value;
  }

  String _parentRemotePath(String path) {
    final cleanPath = _normalizeRemotePath(path);
    if (cleanPath == '/') {
      return '/';
    }
    final lastSlash = cleanPath.lastIndexOf('/');
    if (lastSlash <= 0) {
      return '/';
    }
    return cleanPath.substring(0, lastSlash);
  }

  String _joinRemotePath(String base, String itemName) {
    final cleanBase = _normalizeRemotePath(base);
    final cleanItem = itemName.replaceAll('\\', '/');
    if (cleanBase == '/') {
      return '/$cleanItem';
    }
    return '$cleanBase/$cleanItem';
  }

  String _joinLocalPath(String base, String fileName) {
    final separator = Platform.pathSeparator;
    if (base.endsWith(separator)) {
      return '$base$fileName';
    }
    return '$base$separator$fileName';
  }

  String _nameFromAnyPath(String path) {
    final clean = path.replaceAll('\\', '/');
    if (clean == '/') {
      return '/';
    }
    final parts = clean.split('/');
    if (parts.isEmpty) {
      return path;
    }
    final last = parts.last;
    if (last.isNotEmpty) {
      return last;
    }

    for (var i = parts.length - 1; i >= 0; i--) {
      if (parts[i].isNotEmpty) {
        return parts[i];
      }
    }
    return path;
  }

  String _shellQuote(String value) {
    final escaped = value.replaceAll("'", "'\"'\"'");
    return "'$escaped'";
  }
}
