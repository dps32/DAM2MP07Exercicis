import 'package:flutter/material.dart';
import 'package:exercici05/screens/remote_file_manager_page.dart';

void main() {
  runApp(const ProxmoxFileManagerApp());
}

class ProxmoxFileManagerApp extends StatelessWidget {
  const ProxmoxFileManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestor de Archivos Proxmox',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
      home: const RemoteFileManagerPage(),
    );
  }
}
