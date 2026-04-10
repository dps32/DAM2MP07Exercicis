import 'dart:io';
import 'dart:math';

// Medidas fijas del tablero.
const int boardRows = 6;
const int boardCols = 10;
const int totalMines = 8;


// Lo que puede pedir el usuario en cada turno.
enum CommandType { reveal, toggleFlag, toggleCheat, help, invalid }

// Coordenada simple dentro del tablero.
class Position {
    final int row;
    final int col;

    const Position(this.row, this.col);
}

// Estado interno de cada casilla.
class Cell {
    bool hasMine;
    bool isRevealed;
    bool isFlagged;
    int adjacentMines;

    Cell({
        this.hasMine = false,
        this.isRevealed = false,
        this.isFlagged = false,
        this.adjacentMines = 0,
    });
}

// Comando ya limpio y listo para pasar al motor.
class GameCommand {
    final CommandType type;
    final Position? position;
    final String? errorMessage;

    const GameCommand._(this.type, {this.position, this.errorMessage});

    factory GameCommand.reveal(Position position) {
        return GameCommand._(CommandType.reveal, position: position);
    }

    factory GameCommand.toggleFlag(Position position) {
        return GameCommand._(CommandType.toggleFlag, position: position);
    }

    factory GameCommand.toggleCheat() {
        return const GameCommand._(CommandType.toggleCheat);
    }

    factory GameCommand.help() {
        return const GameCommand._(CommandType.help);
    }

    factory GameCommand.invalid(String message) {
        return GameCommand._(CommandType.invalid, errorMessage: message);
    }
}

// Lo que devolvemos tras ejecutar una accion.
class CommandResult {
    final String? message;
    final bool showHelp;

    const CommandResult({this.message, this.showHelp = false});
}

// Buscaminas
class MinesweeperGame {
    final Random random;
    late List<List<Cell>> board;

    bool cheatEnabled = false;
    bool isGameOver = false;
    bool hasWon = false;
    bool hasMadeFirstReveal = false;
    int revealMoves = 0;

    // Al crear partida montamos tablero y sembramos minas.
    MinesweeperGame({Random? random}) : random = random ?? Random() {
        _initializeBoard();
    }

    // Primero tablero vacio, luego minas y numeros.
    void _initializeBoard() {
        board = List<List<Cell>>.generate(boardRows, (_) {
            final List<Cell> row = <Cell>[];
            for (int col = 0; col < boardCols; col++) {
                row.add(Cell());
            }
            return row;
        });

        _placeMinesWithQuadrants();
        _updateAdjacentCounts();
    }

    // Entrada unica para ejecutar una orden del jugador.
    CommandResult executeCommand(GameCommand command) {
        if (isGameOver) {
            return const CommandResult(message: 'La partida ja ha acabat.');
        }

        switch (command.type) {
            case CommandType.invalid:
                return CommandResult(
                    message: command.errorMessage ?? 'Comanda invalida.',
                );

            case CommandType.help:
                return const CommandResult(showHelp: true);

            case CommandType.toggleCheat:
                cheatEnabled = !cheatEnabled;
                if (cheatEnabled) {
                    return const CommandResult(message: 'Mode trampes activat.');
                }
                return const CommandResult(message: 'Mode trampes desactivat.');

            case CommandType.toggleFlag:
                if (command.position == null) {
                    return const CommandResult(
                        message: 'Falta la posicio de la casella.',
                    );
                }
                return CommandResult(message: _toggleFlag(command.position!));

            case CommandType.reveal:
                if (command.position == null) {
                    return const CommandResult(
                        message: 'Falta la posicio de la casella.',
                    );
                }
                revealMoves++;
                return CommandResult(message: _revealFromUser(command.position!));
        }
    }

    // Toggle de bandera: si hay la quita, si no hay la pone.
    String _toggleFlag(Position position) {
        if (!_isInside(position.row, position.col)) {
            return 'Casella fora de limits.';
        }

        final Cell cell = board[position.row][position.col];

        if (cell.isRevealed) {
            return 'No es pot posar una bandera en una casella descoberta.';
        }

        cell.isFlagged = !cell.isFlagged;

        if (cell.isFlagged) {
            return 'Bandera posada a ${_positionLabel(position)}.';
        }
        return 'Bandera treta de ${_positionLabel(position)}.';
    }

    // Jugada normal de destapar una casilla.
    String _revealFromUser(Position position) {
        if (!_isInside(position.row, position.col)) {
            return 'Casella fora de limits.';
        }

        final Cell targetCell = board[position.row][position.col];

        if (targetCell.isFlagged) {
            return 'La casella te una bandera. Treu-la abans de destapar.';
        }

        if (targetCell.isRevealed) {
            return 'La casella ja estava descoberta.';
        }

        final bool isFirstMove = !hasMadeFirstReveal;
        // Tiramos de la funcion recursiva para no duplicar reglas.
        final bool exploded = _revealCell(
            position.row,
            position.col,
            isFirstMove,
            true,
        );

        if (exploded) {
            isGameOver = true;
            hasWon = false;
            return 'Has explotat una mina.';
        }

        if (board[position.row][position.col].isRevealed) {
            // Solo cuenta como primera jugada si se llego a abrir.
            hasMadeFirstReveal = true;
        }

        if (_hasPlayerWon()) {
            isGameOver = true;
            hasWon = true;
            return 'Has destapat totes les caselles segures.';
        }

        return 'Casella destapada.';
    }

    // Destapado recursivo. Solo explota si el click fue directo del usuario.
    bool _revealCell(int row, int col, bool isFirstMove, bool isUserMove) {
        if (!_isInside(row, col)) {
            return false;
        }

        final Cell cell = board[row][col];

        if (cell.isRevealed || cell.isFlagged) {
            return false;
        }

        if (cell.hasMine) {
            if (isFirstMove) {
                // Primera jugada protegida: movemos la mina y recalculamos.
                _relocateMine(row, col);
                _updateAdjacentCounts();
            } else if (isUserMove) {
                return true;
            } else {
                return false;
            }
        }

        final Cell safeCell = board[row][col];
        safeCell.isRevealed = true;

        if (safeCell.adjacentMines == 0) {
            // Si esta vacia, abrimos vecinos en cascada.
            for (int dRow = -1; dRow <= 1; dRow++) {
                for (int dCol = -1; dCol <= 1; dCol++) {
                    if (dRow == 0 && dCol == 0) {
                        continue;
                    }
                    _revealCell(row + dRow, col + dCol, false, false);
                }
            }
        }

        return false;
    }

    void _placeMinesWithQuadrants() {
        _placeMinesInArea(0, 2, 0, 4, 2);
        _placeMinesInArea(0, 2, 5, 9, 2);
        _placeMinesInArea(3, 5, 0, 4, 2);
        _placeMinesInArea(3, 5, 5, 9, 2);
    }

    // Mete minas al azar dentro de una zona, sin repetir casilla.
    void _placeMinesInArea(
        int rowStart,
        int rowEnd,
        int colStart,
        int colEnd,
        int minesToPlace,
    ) {
        int placedMines = 0;

        while (placedMines < minesToPlace) {
            final int row = rowStart + random.nextInt(rowEnd - rowStart + 1);
            final int col = colStart + random.nextInt(colEnd - colStart + 1);

            if (!board[row][col].hasMine) {
                board[row][col].hasMine = true;
                placedMines++;
            }
        }
    }

    // Si la primera casilla era mina, la movemos a otro hueco libre.
    void _relocateMine(int fromRow, int fromCol) {
        board[fromRow][fromCol].hasMine = false;

        final List<Position> candidates = <Position>[];

        for (int row = 0; row < boardRows; row++) {
            for (int col = 0; col < boardCols; col++) {
                final Cell cell = board[row][col];
                final bool isSource = row == fromRow && col == fromCol;

                if (!isSource && !cell.hasMine && !cell.isRevealed && !cell.isFlagged) {
                    candidates.add(Position(row, col));
                }
            }
        }

        if (candidates.isEmpty) {
            return;
        }

        final Position newPosition = candidates[random.nextInt(candidates.length)];
        board[newPosition.row][newPosition.col].hasMine = true;
    }

    // Recalcula los numeros de alrededor para todas las casillas.
    void _updateAdjacentCounts() {
        for (int row = 0; row < boardRows; row++) {
            for (int col = 0; col < boardCols; col++) {
                final Cell cell = board[row][col];
                if (cell.hasMine) {
                    cell.adjacentMines = 0;
                } else {
                    cell.adjacentMines = _countAdjacentMines(row, col);
                }
            }
        }
    }

    // Cuenta minas en las 8 casillas vecinas.
    int _countAdjacentMines(int row, int col) {
        int mines = 0;

        for (int dRow = -1; dRow <= 1; dRow++) {
            for (int dCol = -1; dCol <= 1; dCol++) {
                if (dRow == 0 && dCol == 0) {
                    continue;
                }

                final int nextRow = row + dRow;
                final int nextCol = col + dCol;

                if (_isInside(nextRow, nextCol) && board[nextRow][nextCol].hasMine) {
                    mines++;
                }
            }
        }

        return mines;
    }

    // Ganamos cuando no queda ninguna casilla segura sin abrir.
    bool _hasPlayerWon() {
        for (int row = 0; row < boardRows; row++) {
            for (int col = 0; col < boardCols; col++) {
                final Cell cell = board[row][col];
                if (!cell.hasMine && !cell.isRevealed) {
                    return false;
                }
            }
        }
        return true;
    }

    // Comprueba limites para no salirnos del tablero.
    bool _isInside(int row, int col) {
        if (row < 0 || row >= boardRows) {
            return false;
        }
        if (col < 0 || col >= boardCols) {
            return false;
        }
        return true;
    }

    // Pinta el tablero en texto para consola.
    String renderBoard({bool showMines = false}) {
        final StringBuffer buffer = StringBuffer();
        buffer.writeln(' 0123456789');

        for (int row = 0; row < boardRows; row++) {
            buffer.write(_rowLabel(row));
            for (int col = 0; col < boardCols; col++) {
                buffer.write(_cellSymbol(board[row][col], showMines));
            }
            buffer.writeln();
        }

        return buffer.toString();
    }

    // Traduce una casilla al simbolo que vera el jugador.
    String _cellSymbol(Cell cell, bool showMines) {
        if (showMines && cell.hasMine) {
            return '*';
        }

        if (cell.isFlagged) {
            return '#';
        }

        if (!cell.isRevealed) {
            return '·';
        }

        if (cell.adjacentMines == 0) {
            return ' ';
        }

        return cell.adjacentMines.toString();
    }
}

// Parser principal de lo que escribe el usuario.
GameCommand parseCommand(String rawInput) {
    final String input = rawInput.trim();

    if (input.isEmpty) {
        return GameCommand.invalid('Comanda buida.');
    }

    final String lowerInput = input.toLowerCase();

    if (lowerInput == 'help' || lowerInput == 'ajuda') {
        return GameCommand.help();
    }

    if (lowerInput == 'cheat' || lowerInput == 'trampes') {
        return GameCommand.toggleCheat();
    }

    final List<String> parts = input.split(RegExp(r'\s+'));

    // Formato corto: solo coordenada, entonces es destapar.
    if (parts.length == 1) {
        final Position? position = parsePosition(parts[0]);
        if (position == null) {
            return GameCommand.invalid('Posicio invalida. Usa format com B2 o D5.');
        }
        return GameCommand.reveal(position);
    }

    // Formato largo: coordenada + accion.
    if (parts.length == 2) {
        final Position? position = parsePosition(parts[0]);
        if (position == null) {
            return GameCommand.invalid('Posicio invalida. Usa format com B2 o D5.');
        }

        final String action = parts[1].toLowerCase();
        if (action == 'flag' || action == 'bandera') {
            return GameCommand.toggleFlag(position);
        }

        return GameCommand.invalid(
            'Accio invalida. Usa flag o bandera per posar o treure bandera.',
        );
    }

    return GameCommand.invalid('Format de comanda invalid.');
}

// Convierte algo como B3 a fila y columna.
Position? parsePosition(String raw) {
    final RegExp format = RegExp(r'^([A-Fa-f])(\d+)$');
    final RegExpMatch? match = format.firstMatch(raw.trim());

    if (match == null) {
        return null;
    }

    final String rowText = match.group(1)!.toUpperCase();
    final String colText = match.group(2)!;
    final int row = rowText.codeUnitAt(0) - 'A'.codeUnitAt(0);
    final int col = int.tryParse(colText) ?? -1;

    if (row < 0 || row >= boardRows) {
        return null;
    }

    if (col < 0 || col >= boardCols) {
        return null;
    }

    return Position(row, col);
}

// Saca la letra de fila (A..F).
String _rowLabel(int row) {
    return String.fromCharCode('A'.codeUnitAt(0) + row);
}

// Junta fila y columna para mostrar posicion.
String _positionLabel(Position position) {
    return '${_rowLabel(position.row)}${position.col}';
}

// Ayuda rapida que se imprime al pedirla.
String buildHelpText() {
    return '''
Comandes disponibles:
- Escollir casella: B2, D5, A0...
- Posar o treure bandera: E1 flag o E1 bandera
- Mostrar o amagar trampes: cheat o trampes
- Ajuda: help o ajuda
''';
}

// Loop de consola: mostrar, leer, ejecutar y repetir.
void main() {
    final MinesweeperGame game = MinesweeperGame();

    stdout.writeln('Exercici 03 - Buscamines');
    stdout.writeln('Escriu help o ajuda per veure les comandes.');

    while (!game.isGameOver) {
        stdout.writeln(game.renderBoard(showMines: game.cheatEnabled));
        stdout.write('Escriu una comanda: ');

        final String? input = stdin.readLineSync();

        if (input == null) {
            // Si se cierra stdin, salimos sin ruido.
            stdout.writeln('\nEntrada finalitzada.');
            return;
        }

        final GameCommand command = parseCommand(input);
        final CommandResult result = game.executeCommand(command);

        if (result.showHelp) {
            stdout.writeln(buildHelpText());
            continue;
        }

        // Si hay feedback, lo mostramos al momento.
        if (result.message != null && result.message!.isNotEmpty) {
            stdout.writeln(result.message);
        }
    }


    // Al final enseñamos minas para cerrar la partida.
    stdout.writeln(game.renderBoard(showMines: true));

    if (game.hasWon) {
        stdout.writeln('Has guanyat!');
    } else {
        stdout.writeln('Has perdut!');
    }

    stdout.writeln('Numero de tirades: ${game.revealMoves}');
}
