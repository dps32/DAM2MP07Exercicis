import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:exercici05/models/disk_tree_node.dart';
import 'package:exercici05/models/remote_entry.dart';
import 'package:exercici05/models/server_config.dart';
import 'package:exercici05/models/server_runtime.dart';
import 'package:exercici05/services/server_config_repository.dart';
import 'package:exercici05/services/ssh_remote_service.dart';
import 'package:exercici05/widgets/bool_status_circle.dart';
import 'package:exercici05/widgets/disk_tree_canvas.dart';
import 'package:exercici05/widgets/hierarchical_selectable_list.dart';
import 'package:exercici05/widgets/labeled_text_field.dart';
import 'package:exercici05/widgets/port_forwarding_widget.dart';
import 'package:exercici05/widgets/server_status_widget.dart';

class RemoteFileManagerPage extends StatefulWidget {
  const RemoteFileManagerPage({super.key});

  @override
  State<RemoteFileManagerPage> createState() => _RemoteFileManagerPageState();
}

class _RemoteFileManagerPageState extends State<RemoteFileManagerPage> {
  final ServerConfigRepository _repository = ServerConfigRepository();
  final SshRemoteService _sshService = SshRemoteService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '22');
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _privateKeyPathController = TextEditingController();
  final TextEditingController _privateKeyPassphraseController = TextEditingController();
  final TextEditingController _initialPathController = TextEditingController(text: '/');

  final TextEditingController _remotePathController = TextEditingController(text: '/');
  final TextEditingController _projectPathController = TextEditingController(text: '/');
  final TextEditingController _diskPathController = TextEditingController(text: '/');
  final TextEditingController _portForwardController = TextEditingController(text: '3000');

  List<ServerConfig> _configs = <ServerConfig>[];
  String? _selectedConfigId;

  List<RemoteEntry> _entries = <RemoteEntry>[];
  RemoteEntry? _selectedEntry;

  ServerRuntimeType _runtimeType = ServerRuntimeType.unknown;
  ServerRuntimeState _runtimeState = ServerRuntimeState.stopped;
  DiskTreeNode? _diskTree;

  bool _loadingConfigs = false;
  bool _connecting = false;
  bool _loadingEntries = false;
  bool _runningRuntimeAction = false;
  bool _loadingDiskTree = false;
  bool _savingConfig = false;
  bool _busyPortForward = false;
  bool _portForwardEnabled = false;

  String _statusText = '';
  String _entryInfoText = '';

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _privateKeyPathController.dispose();
    _privateKeyPassphraseController.dispose();
    _initialPathController.dispose();
    _remotePathController.dispose();
    _projectPathController.dispose();
    _diskPathController.dispose();
    _portForwardController.dispose();
    _sshService.disconnect();
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _loadingConfigs = true;
      _statusText = 'Cargando configuraciones...';
    });

    try {
      final loaded = await _repository.loadConfigs();
      if (!mounted) {
        return;
      }

      setState(() {
        _configs = loaded;
        if (_configs.isNotEmpty) {
          _selectedConfigId = _configs.first.id;
          _fillForm(_configs.first);
        } else {
          _selectedConfigId = null;
          _clearForm();
        }
        _statusText = 'Configuraciones cargadas';
      });
    } catch (error) {
      _setStatus('Error al cargar configuraciones: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingConfigs = false;
        });
      }
    }
  }

  void _fillForm(ServerConfig config) {
    _nameController.text = config.name;
    _hostController.text = config.host;
    _portController.text = '${config.port}';
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _privateKeyPathController.text = config.privateKeyPath;
    _privateKeyPassphraseController.text = config.privateKeyPassphrase;
    _initialPathController.text = config.initialRemotePath;
    _portForwardController.text = '${config.forwardedPort}';
  }

  void _clearForm() {
    _nameController.clear();
    _hostController.clear();
    _portController.text = '22';
    _usernameController.clear();
    _passwordController.clear();
    _privateKeyPathController.clear();
    _privateKeyPassphraseController.clear();
    _initialPathController.text = '/';
    _portForwardController.text = '3000';
  }

  ServerConfig? _findSelectedConfig() {
    if (_selectedConfigId == null) {
      return null;
    }
    for (final config in _configs) {
      if (config.id == _selectedConfigId) {
        return config;
      }
    }
    return null;
  }

  Future<void> _saveConfig() async {
    final name = _nameController.text.trim();
    final host = _hostController.text.trim();
    final user = _usernameController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final forwardedPort = int.tryParse(_portForwardController.text.trim());

    if (name.isEmpty || host.isEmpty || user.isEmpty || port == null) {
      _showError('Nombre, host, usuario y puerto son obligatorios');
      return;
    }

    setState(() {
      _savingConfig = true;
    });

    try {
      final existingId = _selectedConfigId;
      final id = existingId ?? DateTime.now().millisecondsSinceEpoch.toString();

      final config = ServerConfig(
        id: id,
        name: name,
        host: host,
        port: port,
        username: user,
        password: _passwordController.text,
        privateKeyPath: _privateKeyPathController.text.trim(),
        privateKeyPassphrase: _privateKeyPassphraseController.text,
        initialRemotePath: _initialPathController.text.trim().isEmpty
            ? '/'
            : _initialPathController.text.trim(),
        forwardedPort: forwardedPort ?? 3000,
      );

      var replaced = false;
      for (var i = 0; i < _configs.length; i++) {
        if (_configs[i].id == config.id) {
          _configs[i] = config;
          replaced = true;
          break;
        }
      }
      if (!replaced) {
        _configs.add(config);
      }

      await _repository.saveConfigs(_configs);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedConfigId = config.id;
      });
      _setStatus('Configuracion guardada');
    } catch (error) {
      _showError('Error al guardar la configuracion: $error');
    } finally {
      if (mounted) {
        setState(() {
          _savingConfig = false;
        });
      }
    }
  }

  Future<void> _deleteSelectedConfig() async {
    final selected = _findSelectedConfig();
    if (selected == null) {
      return;
    }

    _configs.removeWhere((item) => item.id == selected.id);
    await _repository.saveConfigs(_configs);

    if (!mounted) {
      return;
    }

    setState(() {
      if (_configs.isEmpty) {
        _selectedConfigId = null;
        _clearForm();
      } else {
        _selectedConfigId = _configs.first.id;
        _fillForm(_configs.first);
      }
    });

    if (_sshService.connectedConfig?.id == selected.id) {
      await _sshService.disconnect();
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = <RemoteEntry>[];
        _selectedEntry = null;
        _diskTree = null;
      });
    }

    _setStatus('Configuracion eliminada');
  }

  Future<void> _connectToSelected() async {
    final selected = _findSelectedConfig();
    if (selected == null) {
      _showError('Primero selecciona un servidor');
      return;
    }

    setState(() {
      _connecting = true;
      _statusText = 'Conectando a ${selected.host}:${selected.port}...';
    });

    try {
      await _sshService.connect(selected);
      if (!mounted) {
        return;
      }

      setState(() {
        _remotePathController.text = selected.initialRemotePath;
        _projectPathController.text = selected.initialRemotePath;
        _diskPathController.text = selected.initialRemotePath;
        _portForwardController.text = '${selected.forwardedPort}';
      });

      await _loadDirectory();
      final detectedPort = await _sshService.getForwardedPort80();
      if (!mounted) {
        return;
      }

      setState(() {
        if (detectedPort != null) {
          _portForwardEnabled = true;
          _portForwardController.text = '$detectedPort';
        } else {
          _portForwardEnabled = false;
        }
      });
      _setStatus('Conexion correcta');
    } catch (error) {
      _showError('Error de conexion: $error');
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await _sshService.disconnect();
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = <RemoteEntry>[];
      _selectedEntry = null;
      _entryInfoText = '';
      _diskTree = null;
      _runtimeType = ServerRuntimeType.unknown;
      _runtimeState = ServerRuntimeState.stopped;
      _portForwardEnabled = false;
    });
    _setStatus('Desconectado');
  }

  Future<void> _loadDirectory() async {
    if (!_sshService.isConnected) {
      _showError('Primero conectate a un servidor');
      return;
    }

    final path = _remotePathController.text.trim().isEmpty
        ? '/'
        : _remotePathController.text.trim();
    setState(() {
      _loadingEntries = true;
      _entryInfoText = '';
    });

    try {
      final entries = await _sshService.listDirectory(path);
      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
        _selectedEntry = null;
      });
      _setStatus('Se han cargado ${entries.length} elementos');
    } catch (error) {
      _showError('Error al cargar la carpeta: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingEntries = false;
        });
      }
    }
  }

  Future<void> _goToParentFolder() async {
    final parent = _parentPath(_remotePathController.text.trim());
    _remotePathController.text = parent;
    await _loadDirectory();
  }

  Future<void> _openEntry(RemoteEntry entry) async {
    if (!entry.isDirectory) {
      setState(() {
        _selectedEntry = entry;
      });
      return;
    }

    _remotePathController.text = entry.path;
    await _loadDirectory();
  }

  Future<void> _renameSelectedEntry() async {
    final entry = _selectedEntry;
    if (entry == null) {
      _showError('Primero selecciona un elemento');
      return;
    }

    final controller = TextEditingController(text: entry.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renombrar elemento'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Nombre nuevo',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Renombrar'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (newName == null || newName.trim().isEmpty) {
      return;
    }

    try {
      await _sshService.renameEntry(entry, newName.trim());
      await _loadDirectory();
      _setStatus('Elemento renombrado');
    } catch (error) {
      _showError('Error al renombrar: $error');
    }
  }

  Future<void> _deleteSelectedEntry() async {
    final entry = _selectedEntry;
    if (entry == null) {
      _showError('Primero selecciona un elemento');
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Eliminar'),
              content: Text('Eliminar "${entry.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Eliminar'),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    try {
      await _sshService.deleteEntry(entry);
      await _loadDirectory();
      _setStatus('Elemento eliminado');
    } catch (error) {
      _showError('Error al eliminar: $error');
    }
  }

  Future<void> _downloadSelectedEntry() async {
    final entry = _selectedEntry;
    if (entry == null) {
      _showError('Primero selecciona un elemento');
      return;
    }

    final localDirectory = await FilePicker.getDirectoryPath();
    if (localDirectory == null || localDirectory.trim().isEmpty) {
      return;
    }

    try {
      final savedPath = await _sshService.downloadEntry(entry, localDirectory);
      _setStatus('Descargado en $savedPath');
    } catch (error) {
      _showError('Error al descargar: $error');
    }
  }

  Future<void> _uploadFile() async {
    if (!_sshService.isConnected) {
      _showError('Primero conectate a un servidor');
      return;
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final localPath = result.files.first.path;
    if (localPath == null || localPath.trim().isEmpty) {
      _showError('El archivo seleccionado no tiene ruta valida');
      return;
    }

    try {
      final remotePath = await _sshService.uploadLocalFile(
        localPath,
        _remotePathController.text.trim(),
      );
      await _loadDirectory();
      _setStatus('Archivo subido a $remotePath');
    } catch (error) {
      _showError('Error al subir archivo: $error');
    }
  }

  Future<void> _uploadDirectory() async {
    if (!_sshService.isConnected) {
      _showError('Primero conectate a un servidor');
      return;
    }

    final localDirectory = await FilePicker.getDirectoryPath();
    if (localDirectory == null || localDirectory.trim().isEmpty) {
      return;
    }

    try {
      await _sshService.uploadLocalDirectoryAsZip(
        localDirectory,
        _remotePathController.text.trim(),
      );
      await _loadDirectory();
      _setStatus('Carpeta subida y descomprimida');
    } catch (error) {
      _showError('Error al subir carpeta: $error');
    }
  }

  Future<void> _extractSelectedZip() async {
    final entry = _selectedEntry;
    if (entry == null || entry.isDirectory || !entry.name.endsWith('.zip')) {
      _showError('Primero selecciona un archivo .zip');
      return;
    }

    try {
      await _sshService.extractRemoteZip(
        entry.path,
        _remotePathController.text.trim(),
      );
      await _loadDirectory();
      _setStatus('Zip descomprimido');
    } catch (error) {
      _showError('Error al descomprimir zip: $error');
    }
  }

  Future<void> _showEntryInfo() async {
    final entry = _selectedEntry;
    if (entry == null) {
      _showError('Primero selecciona un elemento');
      return;
    }

    try {
      final text = await _sshService.getEntryInfo(entry);
      if (!mounted) {
        return;
      }
      setState(() {
        _entryInfoText = text;
      });
    } catch (error) {
      _showError('Error al cargar la informacion: $error');
    }
  }

  Future<void> _detectRuntime() async {
    if (!_sshService.isConnected) {
      _showError('Primero conectate a un servidor');
      return;
    }

    final path = _projectPathController.text.trim();
    if (path.isEmpty) {
      _showError('La ruta del proyecto es obligatoria');
      return;
    }

    setState(() {
      _runningRuntimeAction = true;
    });

    try {
      final type = await _sshService.detectRuntimeType(path);
      final state = await _sshService.getRuntimeState(path, type);
      if (!mounted) {
        return;
      }
      setState(() {
        _runtimeType = type;
        _runtimeState = state;
      });
      _setStatus('Runtime detectado: ${runtimeTypeLabel(type)}');
    } catch (error) {
      _showError('Error detectando runtime: $error');
    } finally {
      if (mounted) {
        setState(() {
          _runningRuntimeAction = false;
        });
      }
    }
  }

  Future<void> _runtimeAction(String action) async {
    if (_runtimeType == ServerRuntimeType.unknown) {
      _showError('Primero detecta el tipo de runtime');
      return;
    }

    setState(() {
      _runningRuntimeAction = true;
      if (action == 'restart') {
        _runtimeState = ServerRuntimeState.restarting;
      }
    });

    try {
      final path = _projectPathController.text.trim();
      if (action == 'start') {
        await _sshService.startRuntime(path, _runtimeType);
      } else if (action == 'stop') {
        await _sshService.stopRuntime(path, _runtimeType);
      } else if (action == 'restart') {
        await _sshService.restartRuntime(path, _runtimeType);
      }

      final state = await _sshService.getRuntimeState(path, _runtimeType);
      if (!mounted) {
        return;
      }
      setState(() {
        _runtimeState = state;
      });
      _setStatus('Accion de runtime completada: $action');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _runtimeState = ServerRuntimeState.error;
      });
      _showError('Error en accion de runtime: $error');
    } finally {
      if (mounted) {
        setState(() {
          _runningRuntimeAction = false;
        });
      }
    }
  }

  Future<void> _applyPortForwarding() async {
    if (!_sshService.isConnected) {
      _showError('Primero conectate a un servidor');
      return;
    }

    final targetPort = int.tryParse(_portForwardController.text.trim());
    if (targetPort == null) {
      _showError('El puerto de destino debe ser numerico');
      return;
    }

    setState(() {
      _busyPortForward = true;
    });

    try {
      await _sshService.enablePortForward80(targetPort);
      if (!mounted) {
        return;
      }
      setState(() {
        _portForwardEnabled = true;
      });
      await _persistForwardPort(targetPort);
      _setStatus('Redireccion configurada: 80 -> $targetPort');
    } catch (error) {
      _showError('Error en redireccion de puertos: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busyPortForward = false;
        });
      }
    }
  }

  Future<void> _disablePortForwardingRule() async {
    if (!_sshService.isConnected) {
      _showError('Primero conectate a un servidor');
      return;
    }
    final targetPort = int.tryParse(_portForwardController.text.trim()) ?? 3000;

    setState(() {
      _busyPortForward = true;
    });
    try {
      await _sshService.disablePortForward80(targetPort);
      if (!mounted) {
        return;
      }
      setState(() {
        _portForwardEnabled = false;
      });
      _setStatus('Redireccion eliminada');
    } catch (error) {
      _showError('Error al quitar redireccion: $error');
    } finally {
      if (mounted) {
        setState(() {
          _busyPortForward = false;
        });
      }
    }
  }

  Future<void> _persistForwardPort(int port) async {
    final selected = _findSelectedConfig();
    if (selected == null) {
      return;
    }
    for (var i = 0; i < _configs.length; i++) {
      if (_configs[i].id == selected.id) {
        _configs[i] = _configs[i].copyWith(forwardedPort: port);
        break;
      }
    }
    await _repository.saveConfigs(_configs);
  }

  Future<void> _loadDiskTree() async {
    if (!_sshService.isConnected) {
      _showError('Primero conectate a un servidor');
      return;
    }

    final path = _diskPathController.text.trim();
    if (path.isEmpty) {
      _showError('La ruta para el arbol de disco es obligatoria');
      return;
    }

    setState(() {
      _loadingDiskTree = true;
    });

    try {
      final tree = await _sshService.loadDiskTree(path);
      if (!mounted) {
        return;
      }
      setState(() {
        _diskTree = tree;
      });
      _setStatus('Arbol de disco cargado');
    } catch (error) {
      _showError('Error cargando arbol de disco: $error');
    } finally {
      if (mounted) {
        setState(() {
          _loadingDiskTree = false;
        });
      }
    }
  }

  void _setStatus(String value) {
    if (!mounted) {
      return;
    }
    setState(() {
      _statusText = value;
    });
  }

  void _showError(String value) {
    _setStatus(value);
  }

  void _createNewConfig() {
    setState(() {
      _selectedConfigId = null;
      _clearForm();
    });
  }

  String _parentPath(String path) {
    var value = path.trim();
    if (value.isEmpty || value == '/') {
      return '/';
    }
    value = value.replaceAll('\\', '/');
    while (value.contains('//')) {
      value = value.replaceAll('//', '/');
    }
    if (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    final index = value.lastIndexOf('/');
    if (index <= 0) {
      return '/';
    }
    return value.substring(0, index);
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) {
      return '-';
    }
    final date = '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _findSelectedConfig();
    final connected = _sshService.isConnected;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestor de Archivos Proxmox'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cuentas', icon: Icon(Icons.storage)),
              Tab(text: 'Archivos', icon: Icon(Icons.folder)),
              Tab(text: 'Ejecución', icon: Icon(Icons.settings)),
              Tab(text: 'Árbol Disco', icon: Icon(Icons.pie_chart)),
            ],
          ),
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.transparent,
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      BoolStatusCircle(value: connected),
                      const SizedBox(width: 8),
                      Text(
                        connected
                            ? 'Conectado a ${_sshService.connectedConfig?.name ?? '-'}'
                            : 'Desconectado',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _connecting
                        ? null
                        : connected
                            ? _disconnect
                            : _connectToSelected,
                    icon: Icon(connected ? Icons.link_off : Icons.link),
                    label: Text(connected ? 'Desconectar' : 'Conectar'),
                  ),
                  if (selected != null)
                    Text(
                      '${selected.host}:${selected.port} (${selected.username})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(
                    _statusText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAccountsTab(),
                  _buildFilesTab(),
                  _buildRuntimeTab(),
                  _buildDiskTreeTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountsTab() {
    final listCard = Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
      child: Column(
        children: [
          Expanded(
            child: _loadingConfigs
                ? const Center(child: CircularProgressIndicator())
                : HierarchicalSelectableList(
                    sections: _buildConfigSections(),
                    selectedId: _selectedConfigId,
                    onSelect: (id) {
                      for (final config in _configs) {
                        if (config.id == id) {
                          setState(() {
                            _selectedConfigId = id;
                            _fillForm(config);
                          });
                          break;
                        }
                      }
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _createNewConfig,
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo'),
                ),
                ElevatedButton.icon(
                  onPressed: _savingConfig ? null : _saveConfig,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                ),
                TextButton.icon(
                  onPressed:
                      _selectedConfigId == null ? null : _deleteSelectedConfig,
                  icon: const Icon(Icons.delete),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final formCard = Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            LabeledTextField(label: 'Nombre', controller: _nameController, hintText: 'Mi servidor'),
            const SizedBox(height: 10),
            LabeledTextField(label: 'Host', controller: _hostController, hintText: 'ieticloudpro.ieti.cat'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: LabeledTextField(
                    label: 'Puerto',
                    controller: _portController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LabeledTextField(label: 'Usuario', controller: _usernameController),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LabeledTextField(
              label: 'Contrasena (opcional)',
              controller: _passwordController,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            LabeledTextField(
              label: 'Ruta clave privada (opcional)',
              controller: _privateKeyPathController,
              hintText: '/home/user/.ssh/id_rsa',
            ),
            const SizedBox(height: 10),
            LabeledTextField(
              label: 'Passphrase clave privada (opcional)',
              controller: _privateKeyPassphraseController,
              obscureText: true,
            ),
            const SizedBox(height: 10),
            LabeledTextField(
              label: 'Ruta remota inicial',
              controller: _initialPathController,
              hintText: '/',
            ),
            const SizedBox(height: 10),
            LabeledTextField(
              label: 'Puerto redirigido por defecto',
              controller: _portForwardController,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(width: 320, child: listCard),
          const SizedBox(width: 12),
          Expanded(child: formCard),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 320,
                child: LabeledTextField(
                  label: 'Ruta remota',
                  controller: _remotePathController,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadingEntries ? null : _loadDirectory,
                icon: const Icon(Icons.refresh),
                label: const Text('Cargar'),
              ),
              TextButton.icon(
                onPressed: _loadingEntries ? null : _goToParentFolder,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Subir nivel'),
              ),
              TextButton.icon(
                onPressed: _loadingEntries ? null : _uploadFile,
                icon: const Icon(Icons.upload_file),
                label: const Text('Subir archivo'),
              ),
              TextButton.icon(
                onPressed: _loadingEntries ? null : _uploadDirectory,
                icon: const Icon(Icons.drive_folder_upload),
                label: const Text('Subir carpeta'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
              child: _loadingEntries
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _entries.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final selected = _selectedEntry?.path == entry.path;
                        return ListTile(
                          selected: selected,
                          onTap: () {
                            setState(() {
                              _selectedEntry = entry;
                            });
                          },
                          onLongPress: () => _openEntry(entry),
                          leading: Icon(
                            entry.isDirectory ? Icons.folder : Icons.description,
                          ),
                          title: Text(entry.name),
                          subtitle: Text(
                            'Tam: ${formatBytes(entry.size)}  |  Perm: ${entry.permissions}  |  Mod: ${_formatDate(entry.modifiedAt)}',
                          ),
                          trailing: entry.isDirectory
                              ? const Icon(Icons.subdirectory_arrow_right)
                              : null,
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Acciones del elemento seleccionado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _selectedEntry == null ? null : _renameSelectedEntry,
                        icon: const Icon(Icons.drive_file_rename_outline),
                        label: const Text('Renombrar'),
                      ),
                      TextButton.icon(
                        onPressed: _selectedEntry == null ? null : _downloadSelectedEntry,
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar'),
                      ),
                      TextButton.icon(
                        onPressed: _selectedEntry == null ? null : _deleteSelectedEntry,
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar'),
                      ),
                      TextButton.icon(
                        onPressed: _selectedEntry == null ? null : _showEntryInfo,
                        icon: const Icon(Icons.info),
                        label: const Text('Info + permisos'),
                      ),
                      TextButton.icon(
                        onPressed: (_selectedEntry == null ||
                                _selectedEntry!.isDirectory ||
                                !_selectedEntry!.name.endsWith('.zip'))
                            ? null
                            : _extractSelectedZip,
                        icon: const Icon(Icons.unarchive),
                        label: const Text('Descomprimir zip'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _entryInfoText.isEmpty ? 'Todavia no hay informacion.' : _entryInfoText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuntimeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledTextField(
                    label: 'Ruta del proyecto',
                    controller: _projectPathController,
                    hintText: '/var/www/mi-proyecto',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _runningRuntimeAction ? null : _detectRuntime,
                        icon: const Icon(Icons.search),
                        label: const Text('Detectar runtime'),
                      ),
                      TextButton.icon(
                        onPressed: (_runningRuntimeAction || _runtimeType == ServerRuntimeType.unknown)
                            ? null
                            : () => _runtimeAction('start'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar'),
                      ),
                      TextButton.icon(
                        onPressed: (_runningRuntimeAction || _runtimeType == ServerRuntimeType.unknown)
                            ? null
                            : () => _runtimeAction('restart'),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reiniciar'),
                      ),
                      TextButton.icon(
                        onPressed: (_runningRuntimeAction || _runtimeType == ServerRuntimeType.unknown)
                            ? null
                            : () => _runtimeAction('stop'),
                        icon: const Icon(Icons.stop),
                        label: const Text('Detener'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Tipo: ${runtimeTypeLabel(_runtimeType)}'),
                      const SizedBox(width: 16),
                      ServerStatusWidget(state: _runtimeState),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          PortForwardingWidget(
            enabled: _portForwardEnabled,
            portController: _portForwardController,
            busy: _busyPortForward,
            onEnabledChanged: (enabled) {
              setState(() {
                _portForwardEnabled = enabled;
              });
            },
            onApply: _applyPortForwarding,
            onDisable: _disablePortForwardingRule,
          ),
        ],
      ),
    );
  }

  Widget _buildDiskTreeTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 320,
                child: LabeledTextField(
                  label: 'Ruta para analisis de disco',
                  controller: _diskPathController,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadingDiskTree ? null : _loadDiskTree,
                icon: const Icon(Icons.pie_chart),
                label: const Text('Cargar arbol'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
              child: _loadingDiskTree
                  ? const Center(child: CircularProgressIndicator())
                  : _diskTree == null
                      ? const Center(child: Text('No hay arbol cargado'))
                      : Padding(
                          padding: const EdgeInsets.all(8),
                          child: DiskTreeCanvas(root: _diskTree!),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  List<HierarchySection> _buildConfigSections() {
    final items = <HierarchyItem>[];
    for (final config in _configs) {
      items.add(
        HierarchyItem(
          id: config.id,
          label: config.name,
          detail: '${config.username}@${config.host}:${config.port}',
        ),
      );
    }
    return <HierarchySection>[
      HierarchySection(title: 'Servidores configurados', items: items),
    ];
  }
}
