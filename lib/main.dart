import 'package:flutter/material.dart';
import 'package:new_test/library_page.dart';
import 'package:new_test/record_page.dart';

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
  final int size = 16;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  void _recordPageRedirect() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const RecordPage(title: 'Record Page')),
    );
  }
    void _libraryPageRedirect() {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const LibraryPage(title: 'Library Page')),
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
