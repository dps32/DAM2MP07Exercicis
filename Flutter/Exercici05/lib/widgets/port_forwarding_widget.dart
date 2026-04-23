import 'package:flutter/material.dart';
import 'package:exercici05/widgets/labeled_text_field.dart';

class PortForwardingWidget extends StatelessWidget {
  const PortForwardingWidget({
    super.key,
    required this.enabled,
    required this.portController,
    required this.busy,
    required this.onEnabledChanged,
    required this.onApply,
    required this.onDisable,
  });

  final bool enabled;
  final TextEditingController portController;
  final bool busy;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onApply;
  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Redireccion del puerto 80')),
              Switch(
                value: enabled,
                onChanged: busy ? null : onEnabledChanged,
              ),
            ],
          ),
          LabeledTextField(
            label: 'Puerto de destino',
            controller: portController,
            keyboardType: TextInputType.number,
            enabled: enabled && !busy,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: (!enabled || busy) ? null : onApply,
                child: const Text('Aplicar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: (enabled || busy) ? null : onDisable,
                child: const Text('Quitar regla'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
