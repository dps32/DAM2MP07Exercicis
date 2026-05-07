import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'constants.dart';
import 'drawable.dart';

const functionCallingModel = 'granite4:3b';
const jsonFixModel = 'granite4:3b';

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  int _nextId = 1;
  int? _selectedId;
  Size _canvasSize = const Size(900, 600);
  http.Client? _client;
  HttpClient? _httpClient;

  final List<Drawable> drawables = [];

  // getter simple: si esta cargando mostramos "Esperant ...", si no el texto actual
  String get responseText => _isLoading ? "Esperant ..." : _responseText;
  bool get isLoading => _isLoading;
  int? get selectedId => _selectedId;

  AppData() {
    _resetClient();
  }

  void _resetClient() {
    _httpClient = HttpClient();
    _client = IOClient(_httpClient!);
  }

  void setCanvasSize(Size size) {
    if (size.width <= 0 || size.height <= 0 || size == _canvasSize) {
      return;
    }
    _canvasSize = size;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    selectDrawable(drawable.id);
  }

  void selectDrawable(int? id) {
    _selectedId = id;
    for (final drawable in drawables) {
      drawable.selected = drawable.id == id;
    }
    notifyListeners();
  }

  void selectAt(Offset point) {
    for (final drawable in drawables.reversed) {
      if (drawable.hitTest(point)) {
        selectDrawable(drawable.id);
        return;
      }
    }
    selectDrawable(null);
  }

  Future<dynamic> fixJsonInStrings(dynamic data) async {
    if (data is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        result[entry.key] = await fixJsonInStrings(entry.value);
      }
      return result;
    }
    if (data is List) {
      final result = [];
      for (final item in data) {
        result.add(await fixJsonInStrings(item));
      }
      return result;
    }
    if (data is String) {
      try {
        return fixJsonInStrings(jsonDecode(data));
      } catch (_) {
        if (_looksLikeJsonCandidate(data)) {
          final fixed = await _repairJsonWithAi(data);
          if (fixed != null) {
            return fixJsonInStrings(fixed);
          }
        }
      }
    }
    return data;
  }

  bool _looksLikeJsonCandidate(String value) {
    final trimmed = value.trim();
    return trimmed.startsWith('{') ||
        trimmed.startsWith('[') ||
        ((trimmed.contains('{') || trimmed.contains('[')) &&
            trimmed.contains(':'));
  }

  Future<dynamic> _repairJsonWithAi(String rawJson) async {
    final body = {
      "model": jsonFixModel,
      "stream": false,
      "format": "json",
      "messages": [
        {
          "role": "system",
          "content": "Repair malformed JSON. Return only valid JSON."
        },
        {"role": "user", "content": rawJson}
      ]
    };

    try {
      final response = await _client!.post(
        Uri.parse('http://localhost:11434/api/chat'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      if (response.statusCode != 200) return null;
      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['message']?['content'];
      if (content is! String || content.trim().isEmpty) return null;
      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  dynamic cleanKeys(dynamic value) {
    if (value is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in value.entries) {
        result[entry.key.trim()] = cleanKeys(entry.value);
      }
      return result;
    }
    if (value is List) {
      final result = [];
      for (final item in value) {
        result.add(cleanKeys(item));
      }
      return result;
    }
    return value;
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    final prompt = userPrompt.trim();
    if (prompt.isEmpty) {
      return;
    }

    setLoading(true);

    final messages = [
      {"role": "system", "content": _systemPrompt()},
      {"role": "user", "content": prompt}
    ];

    final body = {
      "model": functionCallingModel,
      "stream": false,
      "messages": messages,
      "tools": tools
    };

    try {
      final response = await _client!.post(
        Uri.parse('http://localhost:11434/api/chat'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final jsonResponse = jsonDecode(response.body);
      final message = jsonResponse['message'];
      final toolCalls = message?['tool_calls'];
      if (toolCalls is List && toolCalls.isNotEmpty) {
        final actions = <String>[];
        for (final raw in toolCalls) {
          final toolCall = cleanKeys(raw);
          if (toolCall is! Map<String, dynamic>) continue;
          final function = toolCall['function'];
          if (function is Map<String, dynamic>) {
            actions.add(await _processFunctionCall(function));
          }
        }
        final parts = <String>[];
        for (final a in actions) {
          if (a.isNotEmpty) parts.add(a);
        }
        _responseText = parts.join('\n');
      } else {
        _responseText = message?['content']?.toString().trim() ??
            "No he rebut cap accio de dibuix.";
      }
    } catch (e) {
      _responseText = "Error contactant amb Ollama: $e";
    }

    setLoading(false);
  }

  String _systemPrompt() {
    return [
      'Ets un assistent de dibuix vectorial dins una app Flutter.',
      'Has de respondre fent servir tool calls sempre que la peticio demani dibuixar, seleccionar, esborrar o modificar.',
      'Canvas actual: ${_canvasSize.width.toStringAsFixed(0)} x ${_canvasSize.height.toStringAsFixed(0)} pixels.',
      'Interpreta percentatges 0..100 o 0..1 segons el text de l usuari.',
      'Expressions com "meitat" volen dir 50%, "diagonal del quadre" vol dir una linia de cantonada a cantonada, i "centre" vol dir 50%, 50%.',
      'Si no hi ha coordenades suficients, tria valors visibles dins el canvas.',
      'Colors: accepta noms comuns o hex #RRGGBB. Mantingues les respostes curtes.'
    ].join('\n');
  }

  void cancelRequests() {
    _httpClient?.close(force: true);
    _resetClient();
    _responseText = "Request cancelled.";
    setLoading(false);
  }

  double parseDouble(dynamic value, [double fallback = 0]) {
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  int? parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double _randomBetween(double min, double max) {
    return min + Random().nextDouble() * (max - min);
  }

  double _percent(dynamic value, double total, double fallback) {
    if (value == null) return fallback;
    final raw = parseDouble(value, fallback);
    final normalized = raw > 1 ? raw / 100 : raw;
    return (normalized * total).clamp(0, total);
  }

  double _x(Map<String, dynamic> p, String key, String percentKey,
      [double? fallback]) {
    if (p[percentKey] != null) {
      return _percent(p[percentKey], _canvasSize.width, fallback ?? 0);
    }
    return parseDouble(
        p[key], fallback ?? _randomBetween(20, _canvasSize.width - 20));
  }

  double _y(Map<String, dynamic> p, String key, String percentKey,
      [double? fallback]) {
    if (p[percentKey] != null) {
      return _percent(p[percentKey], _canvasSize.height, fallback ?? 0);
    }
    return parseDouble(
        p[key], fallback ?? _randomBetween(20, _canvasSize.height - 20));
  }

  Color parseColor(dynamic value, Color fallback) {
    if (value is! String || value.trim().isEmpty) {
      return fallback;
    }
    final text = value.trim().toLowerCase();
    const names = {
      'black': Colors.black,
      'negre': Colors.black,
      'negro': Colors.black,
      'white': Colors.white,
      'blanc': Colors.white,
      'blanco': Colors.white,
      'red': Colors.red,
      'vermell': Colors.red,
      'rojo': Colors.red,
      'green': Colors.green,
      'verd': Colors.green,
      'verde': Colors.green,
      'blue': Colors.blue,
      'blau': Colors.blue,
      'azul': Colors.blue,
      'yellow': Colors.yellow,
      'groc': Colors.yellow,
      'amarillo': Colors.yellow,
      'orange': Colors.orange,
      'taronja': Colors.orange,
      'naranja': Colors.orange,
      'purple': Colors.purple,
      'lila': Colors.purple,
      'morado': Colors.purple,
      'pink': Colors.pink,
      'rosa': Colors.pink,
      'grey': Colors.grey,
      'gray': Colors.grey,
      'gris': Colors.grey,
      'transparent': Colors.transparent,
      'transparentem': Colors.transparent,
      'transparente': Colors.transparent,
    };
    if (names.containsKey(text)) {
      return names[text]!;
    }

    final hex = text.replaceFirst('#', '').replaceFirst('0x', '');
    if (RegExp(r'^[0-9a-f]{6}$').hasMatch(hex)) {
      return Color(int.parse('ff$hex', radix: 16));
    }
    if (RegExp(r'^[0-9a-f]{8}$').hasMatch(hex)) {
      return Color(int.parse(hex, radix: 16));
    }
    return fallback;
  }

  FillGradient parseGradient(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    if (text == 'linear') return FillGradient.linear;
    if (text == 'radial') return FillGradient.radial;
    return FillGradient.none;
  }

  Drawable? _findTarget(Map<String, dynamic> parameters) {
    final id = parseInt(parameters['id']) ?? _selectedId;
    if (id != null) {
      return drawables.where((item) => item.id == id).firstOrNull;
    }
    return drawables.isEmpty ? null : drawables.last;
  }

  Future<String> _processFunctionCall(Map<String, dynamic> functionCall) async {
    final fixedJson = await fixJsonInStrings(functionCall);
    final rawParameters = fixedJson['arguments'];
    final parameters = rawParameters is Map<String, dynamic>
        ? rawParameters
        : <String, dynamic>{};
    final name = fixedJson['name']?.toString() ?? '';

    switch (name) {
      case 'draw_line':
        return _drawLine(parameters);
      case 'draw_circle':
        return _drawCircle(parameters);
      case 'draw_rectangle':
        return _drawRectangle(parameters);
      case 'draw_text':
        return _drawText(parameters);
      case 'select_shape':
        return _selectShape(parameters);
      case 'delete_shape':
        return _deleteShape(parameters);
      case 'update_shape':
        return _updateShape(parameters);
      case 'clear_canvas':
        drawables.clear();
        selectDrawable(null);
        return 'Canvas netejat.';
      default:
        return 'Funcio desconeguda: $name';
    }
  }

  String _drawLine(Map<String, dynamic> p) {
    final start = Offset(
      _x(p, 'startX', 'startPercentX'),
      _y(p, 'startY', 'startPercentY'),
    );
    final end = Offset(
      _x(p, 'endX', 'endPercentX'),
      _y(p, 'endY', 'endPercentY'),
    );
    final line = Line(
      id: _nextId++,
      start: start,
      end: end,
      color: parseColor(p['color'] ?? p['strokeColor'], Colors.black),
      strokeWidth: max(1, parseDouble(p['strokeWidth'], 2)),
    );
    addDrawable(line);
    return 'Linia #${line.id} dibuixada.';
  }

  String _drawCircle(Map<String, dynamic> p) {
    final circle = CircleShape(
      id: _nextId++,
      center: Offset(_x(p, 'x', 'percentX'), _y(p, 'y', 'percentY')),
      radius: max(1, parseDouble(p['radius'], 40)),
      strokeColor: parseColor(p['strokeColor'] ?? p['color'], Colors.black),
      fillColor: parseColor(p['fillColor'], Colors.transparent),
      gradientTo: p['gradientTo'] == null
          ? null
          : parseColor(p['gradientTo'], Colors.white),
      strokeWidth: max(1, parseDouble(p['strokeWidth'], 2)),
      gradient: parseGradient(p['gradient']),
    );
    addDrawable(circle);
    return 'Cercle #${circle.id} dibuixat.';
  }

  String _drawRectangle(Map<String, dynamic> p) {
    final topLeft = Offset(
      _x(p, 'topLeftX', 'topLeftPercentX', 80),
      _y(p, 'topLeftY', 'topLeftPercentY', 80),
    );
    final bottomRight = Offset(
      _x(p, 'bottomRightX', 'bottomRightPercentX', topLeft.dx + 160),
      _y(p, 'bottomRightY', 'bottomRightPercentY', topLeft.dy + 100),
    );
    final rectangle = RectangleShape(
      id: _nextId++,
      topLeft: topLeft,
      bottomRight: bottomRight,
      strokeColor: parseColor(p['strokeColor'] ?? p['color'], Colors.black),
      fillColor: parseColor(p['fillColor'], Colors.transparent),
      gradientTo: p['gradientTo'] == null
          ? null
          : parseColor(p['gradientTo'], Colors.white),
      strokeWidth: max(1, parseDouble(p['strokeWidth'], 2)),
      gradient: parseGradient(p['gradient']),
    );
    addDrawable(rectangle);
    return 'Rectangle #${rectangle.id} dibuixat.';
  }

  String _drawText(Map<String, dynamic> p) {
    final element = TextElement(
      id: _nextId++,
      text: p['text']?.toString() ?? '',
      position: Offset(_x(p, 'x', 'percentX'), _y(p, 'y', 'percentY')),
      color: parseColor(p['color'], Colors.black),
      fontSize: max(6, parseDouble(p['fontSize'], 24)),
      fontFamily: p['fontFamily']?.toString() ?? 'Arial',
      fontWeight: p['bold'] == true ? FontWeight.bold : FontWeight.normal,
      fontStyle: p['italic'] == true ? FontStyle.italic : FontStyle.normal,
    );
    addDrawable(element);
    return 'Text #${element.id} escrit.';
  }

  String _selectShape(Map<String, dynamic> p) {
    final id = parseInt(p['id']);
    if (id != null) {
      final exists = drawables.any((item) => item.id == id);
      selectDrawable(exists ? id : null);
      return exists
          ? 'Figura #$id seleccionada.'
          : 'No existeix la figura #$id.';
    }
    final point = Offset(_x(p, 'x', 'percentX'), _y(p, 'y', 'percentY'));
    selectAt(point);
    return _selectedId == null
        ? 'No hi ha cap figura en aquest punt.'
        : 'Figura #$_selectedId seleccionada.';
  }

  String _deleteShape(Map<String, dynamic> p) {
    final id = parseInt(p['id']) ?? _selectedId;
    if (id == null) {
      return 'No hi ha cap figura seleccionada.';
    }
    final before = drawables.length;
    drawables.removeWhere((item) => item.id == id);
    selectDrawable(null);
    return drawables.length < before
        ? 'Figura #$id esborrada.'
        : 'No existeix la figura #$id.';
  }

  String _updateShape(Map<String, dynamic> p) {
    final target = _findTarget(p);
    if (target == null) {
      return 'No hi ha cap figura per modificar.';
    }

    final values = <String, dynamic>{};
    final point = Offset(
      _x(p, 'x', 'percentX', double.nan),
      _y(p, 'y', 'percentY', double.nan),
    );

    if (!point.dx.isNaN && !point.dy.isNaN) {
      if (target is Line) {
        final delta = point - target.start;
        values['start'] = point;
        values['end'] = target.end + delta;
      } else if (target is CircleShape) {
        values['center'] = point;
      } else if (target is RectangleShape) {
        final size = target.rect.size;
        values['topLeft'] = point;
        values['bottomRight'] =
            Offset(point.dx + size.width, point.dy + size.height);
      } else if (target is TextElement) {
        values['position'] = point;
      }
    }

    if (target is Line && p['endX'] != null && p['endY'] != null) {
      values['end'] = Offset(parseDouble(p['endX']), parseDouble(p['endY']));
    }
    if (target is RectangleShape &&
        (p['width'] != null || p['height'] != null)) {
      final width = parseDouble(p['width'], target.rect.width);
      final height = parseDouble(p['height'], target.rect.height);
      values['bottomRight'] =
          Offset(target.topLeft.dx + width, target.topLeft.dy + height);
    }

    if (p['radius'] != null) {
      values['radius'] = max(1, parseDouble(p['radius']));
    }
    if (p['strokeWidth'] != null) {
      values['strokeWidth'] = max(1, parseDouble(p['strokeWidth']));
    }
    if (p['strokeColor'] != null || p['color'] != null) {
      values[target is TextElement || target is Line
              ? 'color'
              : 'strokeColor'] =
          parseColor(p['strokeColor'] ?? p['color'], Colors.black);
    }
    if (p['fillColor'] != null) {
      values['fillColor'] = parseColor(p['fillColor'], Colors.transparent);
    }
    if (p['gradientTo'] != null) {
      values['gradientTo'] = parseColor(p['gradientTo'], Colors.white);
    }
    if (p['gradient'] != null) {
      values['gradient'] = parseGradient(p['gradient']);
    }
    if (p['text'] != null) values['text'] = p['text'].toString();
    if (p['fontSize'] != null) {
      values['fontSize'] = max(6, parseDouble(p['fontSize']));
    }
    if (p['fontFamily'] != null) {
      values['fontFamily'] = p['fontFamily'].toString();
    }
    if (p['bold'] != null) {
      values['fontWeight'] =
          p['bold'] == true ? FontWeight.bold : FontWeight.normal;
    }
    if (p['italic'] != null) {
      values['fontStyle'] =
          p['italic'] == true ? FontStyle.italic : FontStyle.normal;
    }

    target.update(values);
    selectDrawable(target.id);
    return 'Figura #${target.id} modificada.';
  }
}
