import 'package:flutter/material.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key, required this.title});
  final String title;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class Recording {
  final String id;
  final String title;
  final String duration;

  Recording({required this.id, required this.title, required this.duration});
}

class _LibraryPageState extends State<LibraryPage> {

  final List<Recording> recordings = [
    Recording(id: '1', title: 'song draft 1', duration: '3:45'),
    Recording(id: '2', title: 'Passive demo', duration: '4:20'),
    Recording(id: '3', title: 'song2', duration: '2:55'),
    Recording(id: '4', title: 'demo drums', duration: '5:10'),
    Recording(id: '5', title: 'Liberation practice', duration: '3:30'),
  ];


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('Recordings'),
      ),
      body: ListView.builder(
        itemCount: recordings.length,
        itemBuilder: (context, index) {
          final recording = recordings[index];
          return ListTile(
            leading: Icon(Icons.audiotrack),
            title: Text(recording.title),
            subtitle: Text('Duration: ${recording.duration}'),
            trailing: IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () {},
            ),
          );
        },
      ),
    );
  }
}
