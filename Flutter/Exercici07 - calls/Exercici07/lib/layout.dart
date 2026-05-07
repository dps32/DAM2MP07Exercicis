import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cupertino_desktop_kit/cdk.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'canvas_painter.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.title});

  final String title;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  late final ScrollController _scrollController;
  late final TextEditingController _textController;
  late final String _placeholder;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _textController = TextEditingController();
    final random = Random();
    final placeholders = [
      'Dibuixa una linia vermella a la diagonal del quadre',
      'Fes un cercle blau al centre amb radi 60',
      'Dibuixa un rectangle amb gradient radial de groc a taronja',
      'Escriu "Hola" en negreta al 50% del canvas',
      'Selecciona la figura 1 i posa-li el contorn verd',
    ];
    _placeholder = placeholders[random.nextInt(placeholders.length)];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendPrompt(AppData appData) {
    final userPrompt = _textController.text;
    appData.callWithCustomTools(userPrompt: userPrompt);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      appData.setCanvasSize(size);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          appData.selectAt(details.localPosition);
                        },
                        child: Container(
                          color: CupertinoColors.systemGrey5,
                          child: CustomPaint(
                            painter: CanvasPainter(
                              drawables: appData.drawables,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: CupertinoScrollbar(
                            controller: _scrollController,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              child: SizedBox(
                                width: double.infinity,
                                child: Text(
                                  appData.responseText,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: CDKFieldText(
                            maxLines: 5,
                            controller: _textController,
                            placeholder: _placeholder,
                            enabled: !appData.isLoading,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: CDKButton(
                                style: CDKButtonStyle.action,
                                onPressed: appData.isLoading
                                    ? null
                                    : () => _sendPrompt(appData),
                                child: const Text('Query'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CDKButton(
                                onPressed: appData.isLoading
                                    ? () => appData.cancelRequests()
                                    : null,
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (appData.isLoading)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
                  child: const Center(
                    child: CupertinoActivityIndicator(radius: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
