import 'package:blitzgedanke/screens/game/game_manager.dart';
import 'package:blitzgedanke/screens/game/wheel_widget.dart';
import 'package:blitzgedanke/utils/R.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key, required this.manager}) : super(key: key);
  final GameManager manager;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _wheelKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
      child: BlocBuilder<GameManager, GameState>(
        builder: (context, state) => _createGame(context, state),
        bloc: widget.manager,
      ),
    ));
  }

  Widget _createGame(BuildContext context, GameState state) {
    if (state is BeforeGameState) {
      return Column(
        children: [
          _buildWheel(state.canStart),
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Wrap(
                children: state.players
                    .map((e) => _buildPlayerDeletableButton(e))
                    .toList(),
              ),
            ),
          ),
          addPlayerButton(context),
        ],
      );
    } else if (state is RunningGameState) {
      final endGameButton = Expanded(
        flex: 2,
        child: Container(
          alignment: Alignment.bottomCenter,
          child: TextButton(
              onPressed: () {
                widget.manager.endGame();
              },
              child: Opacity(
                opacity: 0.5,
                child: Text(
                  R.strings.buttonStopGame,
                  style: R.styles.player(context),
                ),
              )),
        ),
      );

      final opacity = state.card.isEmpty ? 0.1 : 1.0;
      final users = Expanded(
        flex: 6,
        child: Opacity(
          opacity: opacity,
          child: SingleChildScrollView(
            child: Wrap(
              children: state.players.map((e) {
                final highlighted = state.selectedPlayer == null
                    ? null
                    : state.selectedPlayer == e;
                return _buildPlayerButton(e, highlighted);
              }).toList(),
            ),
          ),
        ),
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCard(state),
          Expanded(flex: 10, child: _buildWheel(true)),
          Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                R.strings.whoWasFirstInThisRound,
                style: R.styles.explanation(context),
              ),
            ),
          ),
          users,
          endGameButton,
        ],
      );
    } else if (state is EndGameState) {
      final entries = state.results.entries.toList();
      entries.sort((a, b) => b.value.compareTo(a.value));
      var lastPosition = 0;
      var lastScore = -1;
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              R.strings.finalScore,
              style: R.styles.title(context),
            ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemBuilder: (ctx, i) {
                  final e = entries[i];
                  if (lastScore != e.value) {
                    lastPosition++;
                  }
                  lastScore = e.value;
                  return _buildResult(lastPosition, e.key, e.value);
                },
                itemCount: state.results.length,
              ),
            ),
            TextButton(
                onPressed: () => widget.manager.restartGame(),
                child: Text(
                  R.strings.startGame.toUpperCase(),
                  style: R.styles.button(context),
                ))
          ],
        ),
      );
    } else {
      throw "$state not supported";
    }
  }

  Widget addPlayerButton(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        alignment: Alignment.bottomCenter,
        child: _addNewPlayer(context),
      ),
    );
  }

  Widget _buildResult(int position, String player, int cardsWon) {
    return _buildCardButton(
      Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              "$position.",
              textAlign: TextAlign.center,
              style: R.styles.player(context),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              player,
              textAlign: TextAlign.center,
              style: R.styles.player(context),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              cardsWon.toString(),
              textAlign: TextAlign.center,
              style: R.styles.player(context),
            ),
          )
        ],
      ),
      background: R.colors.playerCardBackground,
    );
  }

  Widget _buildPlayerButton(String player, bool? highlighted) {
    return Opacity(
      opacity: highlighted == null
          ? 1.0
          : highlighted
              ? 1.0
              : 0.5,
      child: _buildCardButton(
        Text(
          player.toUpperCase(),
          style: R.styles.player(context),
        ),
        onTap: () => widget.manager.selectWinningPlayer(player),
        background: R.colors.playerCardBackground,
      ),
    );
  }

  Widget _buildPlayerDeletableButton(String player) {
    return _buildCardButton(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              CupertinoIcons.xmark_circle,
              size: 20,
            ),
          ),
          Text(
            player.toUpperCase(),
            style: R.styles.player(context),
          ),
        ],
      ),
      onTap: () => widget.manager.removePlayer(player),
      background: R.colors.playerCardBackground,
    );
  }

  Widget _addNewPlayer(BuildContext context) {
    return TextButton(
        child: Text(
          R.strings.addPlayer.toUpperCase(),
          style: R.styles.player(context),
        ),
        onPressed: () async {
          final name = await _showNewPlayerDialog(context);
          if (name != null) {
            widget.manager.addPlayer(name);
          }
        });
  }

  Widget _buildWheel(bool canStart) {
    return IgnorePointer(
      ignoring: !canStart,
      child: Opacity(
        opacity: canStart ? 1.0 : 0.3,
        child: WheelWidget(
          key: _wheelKey,
          onFinished: (int position) {
            widget.manager.onSpinFinished(position);
          },
          onRotationStart: () {
            widget.manager.onSpinStarted();
          },
        ),
      ),
    );
  }

  _buildCard(RunningGameState state) {
    return _buildCardButton(
      Text(
        state.card,
        textAlign: TextAlign.center,
        style: R.styles.gameCard(context),
      ),
      onTap: widget.manager.cardPressed,
      description: Text(
        state.roundOver
            ? R.strings.descriptionTurnTheWheel
            : R.strings.descriptionSkipCard,
        style: R.styles.gameCardDescription(context),
      ),
      minHeight: 150,
      minWidth: 300,
      background: R.colors.cardBackground,
      disabled: state.roundOver || state.card.isEmpty,
    );
  }

  Widget _buildCardButton(
    Widget child, {
    VoidCallback? onTap,
    Widget? description,
    double? minHeight,
    double? minWidth,
    Color? background,
    bool disabled = false,
  }) {
    if (minWidth != null || minHeight != null) {
      child = ConstrainedBox(
        constraints:
            BoxConstraints(minWidth: minWidth ?? 0, minHeight: minHeight ?? 0),
        child: Center(child: child),
      );
    }

    var content = description == null
        ? child
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: child,
                flex: 0,
              ),
              description
            ],
          );

    return IgnorePointer(
      ignoring: disabled || onTap == null,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            color: background,
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> _showNewPlayerDialog(BuildContext context) async {
  final _controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                  labelText: R.strings.playerName, hintText: 'eg. John Smith'),
            ),
          )
        ],
      ),
      actions: <Widget>[
        TextButton(
            child: Text(R.strings.buttonCancel),
            onPressed: () {
              Navigator.pop(context);
            }),
        TextButton(
            child: Text(R.strings.buttonOk),
            onPressed: () {
              Navigator.pop(context, _controller.text);
            })
      ],
    ),
  );
}
