import 'package:flutter/material.dart';
import 'package:exercici05/models/server_runtime.dart';

class ServerStatusWidget extends StatelessWidget {
  const ServerStatusWidget({
    super.key,
    required this.state,
  });

  final ServerRuntimeState state;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 6),
        Text(
          runtimeStateLabel(state),
          style: TextStyle(color: color),
        ),
      ],
    );
  }

  Color _statusColor(ServerRuntimeState value) {
    switch (value) {
      case ServerRuntimeState.running:
        return Colors.green;
      case ServerRuntimeState.stopped:
        return Colors.grey;
      case ServerRuntimeState.restarting:
        return Colors.orange;
      case ServerRuntimeState.error:
        return Colors.red;
    }
  }
}
