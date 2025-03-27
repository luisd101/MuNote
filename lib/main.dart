import 'package:flutter/material.dart';
import 'package:new_test/library_page.dart';
import 'package:new_test/record_page.dart';
import 'package:new_test/audio_processor.dart';
import 'package:permission_handler/permission_handler.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MuNote',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'MuNote'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _audioService.init();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.storage.request();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
  void _recordPageRedirect() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RecordPage(title: 'Record Page', audioService: _audioService,)),
    );
  }
    void _libraryPageRedirect() {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LibraryPage(title: 'Library Page', audioService: _audioService,)),
      );
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.primaryFixed,

        title: Text(widget.title),
      ),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget> [
            Expanded(child:
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.3,
                margin: EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _recordPageRedirect,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100]
                    ),
                  child: Text('Record a new idea.',
                    style: TextStyle(fontSize: 24, color: Colors.black)
                  )
                )
              )
            ),
            Expanded(child:
              Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.width * 0.3,
                  margin: EdgeInsets.all(20),
                  child: ElevatedButton(
                      onPressed: _libraryPageRedirect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple[100]
                      ),
                      child: Text('Listen to an existing idea.',
                        style: TextStyle(fontSize: 24, color: Colors.black)
                      )
                  )
              )
            )
          ]
        )
      )
    );
  }
}
