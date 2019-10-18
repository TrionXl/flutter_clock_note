import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import './dbhelper.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'take_a_time_note',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.pink,
      ),
      home: MyHomePage(title: 'take_a_time_note'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

const oneSec = const Duration(seconds: 1);

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  String nowTime = '';
  String _text = "double_click or long_press";
  Timer _timer;

  DbProvider _dbProvider = DbProvider();
  Future<String> _asyncInputDialog(BuildContext context) async {
    String text = "";
    return showDialog<String>(
      context: context,
      barrierDismissible:
          false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          //title: Text('Enter current team'),
          content: new Row(
            children: <Widget>[
              new Expanded(
                  child: new TextField(
                autofocus: true,
                decoration: new InputDecoration(labelText: '', hintText: 'say something'),
                onChanged: (value) {
                  text = value;
                },
              ))
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('save'),
              onPressed: () {
                if(text==null){
                  text='';
                }
                Navigator.of(context).pop(text);
              },
            ),
          ],
        );
      },
    );
  }

  startCountdownTimer() {
    var callback = (timer) => {
          setState(() {
            nowTime = getTimeString();
          })
        };
    _timer = Timer.periodic(oneSec, callback);
  }

  @override
  void dispose() {
    _dbProvider.close();
  }

  void initState() {
    super.initState();
    /* animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 5));*/
    //_dbProvider=DbProvider();
    _dbProvider.creat();

    startCountdownTimer();
  }

  Tell _tell = Tell();
  String getTimeString() {
    var start = 1527170700;
    var now = 0;
    var day = 0;
    var hours = 0;
    var min = 0;
    var sed = 0;
    now = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    day = ((now - start) / (24 * 60 * 60) - 0.5).round();
    hours = (((now - (day * 24 * 60 * 60) - start) / (60 * 60)) - 0.5).round();
    min = ((now - hours * 60 * 60 - day * 24 * 60 * 60 - start) / 60 - 0.5)
        .round();
    sed = (now - hours * 60 * 60 - day * 24 * 60 * 60 - min * 60 - start);
    return "$day $hours $min $sed";
  }

  void virb() {
    //if (Vibration.hasVibrator()) {
    Vibration.vibrate(duration: 70);
    //}
  }

  getAll() async {
    var list = await _dbProvider.getAll();
    String clipShow="";
    list.forEach((T){
      clipShow=clipShow+"${T.time} ${T.tell}"+'\n';
    });
    Clipboard.setData(new ClipboardData(text: clipShow));
    return list;
  }

  getRanTell() async {
    var list = await getAll();
    var ran = Random.secure().nextInt(list.length);
    return list[ran].tell;
  }

  toStore() {}
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            GestureDetector(
              child: Text(
                _text,
                style: TextStyle(color: Colors.pink, fontSize: 28),
              ),
              onLongPress: () async {
                print("down");
                var tell = await getRanTell();
                setState(() {
                  if (tell != null) {
                    this._text = tell;
                  }
                });
              },
              onTap: () {
                print('db open is ${_dbProvider.db.isOpen}');
                print('db is ${_dbProvider.db.path}');
              },
              onLongPressUp: () {
                virb();
              },
              onDoubleTap: () async {
                _scaffoldKey.currentState.showSnackBar(new SnackBar(
                  content: Text(''),
                  action: SnackBarAction(
                      label: "oneclick",
                      onPressed: () async {
                        final String text = await _asyncInputDialog(context);
                        if (text != null && text!="") {
                          _text = text;
                          _tell.tell = text;
                          var id = await _dbProvider.insert(_tell);
                          print('id = ${id.id}');
                          return ;
                        }
                      }),
                ));
              },
            ),
            Text(
              nowTime,
              style: TextStyle(color: Colors.blue, fontSize: 38),
            ),
            Text("from 2018/5/24 22:5:0")
          ],
        ),
      ),
    );
  }
}
