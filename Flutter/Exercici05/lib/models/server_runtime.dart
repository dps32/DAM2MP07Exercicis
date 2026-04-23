enum ServerRuntimeType { unknown, node, java }

enum ServerRuntimeState { stopped, running, restarting, error }

String runtimeTypeLabel(ServerRuntimeType type) {
  switch (type) {
    case ServerRuntimeType.node:
      return 'NodeJS';
    case ServerRuntimeType.java:
      return 'Java';
    case ServerRuntimeType.unknown:
      return 'Desconocido';
  }
}

String runtimeStateLabel(ServerRuntimeState state) {
  switch (state) {
    case ServerRuntimeState.running:
      return 'En ejecución';
    case ServerRuntimeState.stopped:
      return 'Detenido';
    case ServerRuntimeState.restarting:
      return 'Reiniciando';
    case ServerRuntimeState.error:
      return 'Error';
  }
}
