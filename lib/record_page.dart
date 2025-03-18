import 'package:flutter/material.dart';


class RecordPage extends StatefulWidget {
  const RecordPage({super.key, required this.title});

  final String title;


  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {

      _counter += 2;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryFixed,
        title: Text(widget.title),
      ),
      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
                iconSize: 200,
                onPressed: _incrementCounter,
                icon: const Icon(Icons.mic),
                color: Colors.red
            ),
            TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter Notes Here',
              ),
            ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
