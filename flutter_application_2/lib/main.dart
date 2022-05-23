import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'sql_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final darkBlue = Color.fromARGB(255, 18, 32, 47);
    return MaterialApp(
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: darkBlue),
      debugShowCheckedModeBanner: false,
      home: GameWidget(),
      routes: <String, WidgetBuilder> {
        '/DataScore' : (context) => DataScore(),
      },
    );
  }
}

const _targetColors = [Colors.orange, Colors.green, Colors.yellow, Colors.blue];
const _textColors = [Colors.blue, Colors.yellow, Colors.green, Colors.orange];
const _colorNames = ['orange', 'green', 'yellow', 'blue'];

enum TargetType { color, number }

class TargetData {
  TargetData({required this.type, required this.index});
  final TargetType type;
  final int index;

  String get text => type == TargetType.color
      ? 'COLOR ${_colorNames[index]}'
      : 'NUMBER $index';
  Color get color => _textColors[index];
}

class GameTimer {
  Timer? _timer;
  ValueNotifier<int> remainingSeconds = ValueNotifier<int>(10);
  

  void startGame() {
    _timer?.cancel();
    remainingSeconds.value = 15;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      remainingSeconds.value--;
      if (remainingSeconds.value == 0) {
        _timer?.cancel();
      }
    });
  }
}

class GameWidget extends StatefulWidget {
  @override
  _GameWidgetState createState() => _GameWidgetState();
}

class _GameWidgetState extends State<GameWidget> {
  static final _rng = Random();

  late Alignment _playerAlignment;
  late List<Alignment> _targets;
  late TargetData _targetData;
  int _score = 0;
  bool _gameInProgress = false;
  GameTimer _gameTimer = GameTimer();

  @override
  void initState() {
    super.initState();
    _playerAlignment = Alignment(0, 0);
    _gameTimer.remainingSeconds.addListener(() {
      if (_gameTimer.remainingSeconds.value == 0) {
        setState(() {

          _gameInProgress = false;
        });
        _addItem();
      }
    });
    _randomize();
  }
  Future<void> _addItem() async {
        await SQLHelper.createItem(
        _score.toString());
        }
  void _randomize() {
    _targetData = TargetData(
      type: TargetType.values[_rng.nextInt(2)],
      index: _rng.nextInt(_targetColors.length),
    );
    _targets = [
      for (var i = 0; i < _targetColors.length; i++)
        Alignment(
          _rng.nextDouble() * 2 - 1,
          _rng.nextDouble() * 2 - 1,
        )
    ];
  }

  void _startGame() {
    _randomize();
    setState(() {
      _score = 0;
      _gameInProgress = true;
    });
    _gameTimer.startGame();
  }

  // This method contains most of the game logic
  void _handleTapDown(TapDownDetails details, int? selectedIndex) {
    if (!_gameInProgress) {
      return;
    }
    final size = MediaQuery.of(context).size;
    setState(() {
      if (selectedIndex != null) {
        _playerAlignment = _targets[selectedIndex];
        final didScore = selectedIndex == _targetData.index;
        Future.delayed(Duration(milliseconds: 250), () {
          setState(() {
            if (didScore) {
              _score++;
            } else {
              _score--;
            }
            _randomize();
          });
        });
        // score point
      } else {
        _playerAlignment = Alignment(
          2 * (details.localPosition.dx / size.width) - 1,
          2 * (details.localPosition.dy / size.height) - 1,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Handle taps anywhere
          Positioned.fill(
            child: GestureDetector(
              onTapDown: (details) => _handleTapDown(details, null),
            ),
          ),
          // Player
          // TO DO: Convert to AnimatedAlign & add a duration argument
          AnimatedAlign(
  alignment: _playerAlignment,
  // 2. Add a duration
  duration: Duration(milliseconds: 250),
  child: Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      color: _targetData.color,
      shape: BoxShape.circle,
    ),
  ),
),
          // Targets
         for (var i = 0; i < _targetColors.length; i++)
  GestureDetector(
    // Handle taps on targets
    onTapDown: (details) => _handleTapDown(details, i),
    // 1. convert to AnimatedAlign
    child: AnimatedAlign(
      alignment: _targets[i],
      // 2. Add a duration
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Target(
        color: _targetColors[i],
        textColor: _textColors[i],
        text: i.toString(),
      ),
    ),
  ),
          // Next Command
          Align(
            alignment: Alignment(0, 0),
            child: IgnorePointer(
              ignoring: _gameInProgress,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextPrompt(
                    'Score: $_score',
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  TextPrompt(
                    _gameInProgress ? 'Tap ${_targetData.text}' : 'Game Over!',
                    color: _gameInProgress ? _targetData.color : Colors.white,
                  ),

                  _gameInProgress
                      ? ValueListenableBuilder(
                          valueListenable: _gameTimer.remainingSeconds,
                          builder: (context, remainingSeconds, _) {
                            return TextPrompt(remainingSeconds.toString(),
                                color: Colors.white);
                          },
                        )
                      : OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: StadiumBorder(),
                            side: BorderSide(width: 2, color: Colors.white),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextPrompt('Start', color: Colors.white),
                          ),
                          onPressed: _startGame,
                        ),
                  _gameInProgress
                      ? ValueListenableBuilder(
                          valueListenable: _gameTimer.remainingSeconds,
                          builder: (context, remainingSeconds, _) {
                            return TextPrompt('',
                                color: Colors.white);
                          },
                        )
                      : OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: StadiumBorder(),
                            side: BorderSide(width: 2, color: Colors.white),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextPrompt('.......', color: Colors.white),
                          ),
                          onPressed:() {
                            Navigator.pushNamed(context, '/DataScore');
                          },
                        ),
                      
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Target extends StatelessWidget {
  const Target({
    Key? key,
    required this.color,
    required this.textColor,
    required this.text,
  }) : super(key: key);
  final Color color;
  final Color textColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75,
      height: 75,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Align(
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 50,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class TextPrompt extends StatelessWidget {
  const TextPrompt(
    this.text, {
    Key? key,
    required this.color,
    this.fontSize = 32,
  }) : super(key: key);
  final String text;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedDefaultTextStyle(
      child: Text(text),
      duration: Duration(milliseconds: 250),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        shadows: [
          Shadow(
            blurRadius: 4.0,
            color: Colors.black,
            offset: Offset(0.0, 2.0),
          ),
        ],
      ),
    );
  }
}

//class DataScore extends StatelessWidget {
  //@override
  //Widget build(BuildContext context) {
    //return Scaffold(
      //appBar: AppBar(title: Text("Score"),),
    //);
  //}
//}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
class DataScore extends StatelessWidget {
  const DataScore({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // Remove the debug banner
        appBar: AppBar(title: Text("Score"),),
        body: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // All journals
  List<Map<String, dynamic>> _journals = [];

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final TextEditingController _scoreController = TextEditingController();
  final TextEditingController _createdAtController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
 
// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _scoreController.text);
    _refreshJournals();
  }

  // Update an existing journal
  //Future<void> _updateItem(int id) async {
    //await SQLHelper.updateItem(
       // id, _scoreController.text);
    //_refreshJournals();
  //}

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a journal!'),
    ));
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _journals.length,
              itemBuilder: (context, index) => Card(
                color: Colors.orange[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                    title: Text(_journals[index]['createdAt']),
                    subtitle: Text(_journals[index]['score']),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteItem(_journals[index]['id']),
                          ),
                        ],
                      ),
                    )),
              ),
            ),
      //floatingActionButton: FloatingActionButton(
        //child: const Icon(Icons.add),
        //onPressed: () => _showForm(null),
      //),
    );
  }
}
