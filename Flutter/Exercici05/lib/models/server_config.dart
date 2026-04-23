class ServerConfig {
  const ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.privateKeyPath,
    required this.privateKeyPassphrase,
    required this.initialRemotePath,
    required this.forwardedPort,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final String privateKeyPath;
  final String privateKeyPassphrase;
  final String initialRemotePath;
  final int forwardedPort;

  ServerConfig copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    String? privateKeyPath,
    String? privateKeyPassphrase,
    String? initialRemotePath,
    int? forwardedPort,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      privateKeyPassphrase: privateKeyPassphrase ?? this.privateKeyPassphrase,
      initialRemotePath: initialRemotePath ?? this.initialRemotePath,
      forwardedPort: forwardedPort ?? this.forwardedPort,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'privateKeyPath': privateKeyPath,
      'privateKeyPassphrase': privateKeyPassphrase,
      'initialRemotePath': initialRemotePath,
      'forwardedPort': forwardedPort,
    };
  }

  static ServerConfig fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: _readString(json['id'], ''),
      name: _readString(json['name'], ''),
      host: _readString(json['host'], ''),
      port: _readInt(json['port'], 22),
      username: _readString(json['username'], ''),
      password: _readString(json['password'], ''),
      privateKeyPath: _readString(json['privateKeyPath'], ''),
      privateKeyPassphrase: _readString(json['privateKeyPassphrase'], ''),
      initialRemotePath: _readString(json['initialRemotePath'], '/'),
      forwardedPort: _readInt(json['forwardedPort'], 3000),
    );
  }

  static List<ServerConfig> listFromDynamic(dynamic raw) {
    final servers = <ServerConfig>[];
    if (raw is! List) {
      return servers;
    }

    for (final item in raw) {
      if (item is! Map) {
        continue;
      }

      final mapped = <String, dynamic>{};
      for (final entry in item.entries) {
        final key = '${entry.key}';
        mapped[key] = entry.value;
      }
      servers.add(fromJson(mapped));
    }
    return servers;
  }

  static String _readString(dynamic raw, String fallback) {
    if (raw is String) {
      return raw;
    }
    if (raw == null) {
      return fallback;
    }
    return '$raw';
  }

  static int _readInt(dynamic raw, int fallback) {
    if (raw is int) {
      return raw;
    }
    if (raw is double) {
      return raw.toInt();
    }
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) {
        return parsed;
      }
    }
    return fallback;
  }
}
