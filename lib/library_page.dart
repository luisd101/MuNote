import 'package:flutter/material.dart';
import 'package:new_test/audio_processor.dart';


class LibraryPage extends StatefulWidget {
  final AudioService audioService;
  const LibraryPage({super.key, required this.title, required this.audioService});


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
      body: widget.audioService.audioFiles.isEmpty
          ? const Center(child: Text('No recordings available.'))
          : ListView.builder(
        itemCount: widget.audioService.audioFiles.length,
        itemBuilder: (context, index) {
          String path = widget.audioService.audioFiles[index];
          String fileName = path.split('/').last;
          return ListTile(
            title: Text(fileName),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () async {
                await widget.audioService.playAudio(path);
              },
            ),
            onTap: () async {
              await widget.audioService.playAudio(path);
            },
          );
        },
      ),
    );
  }
}
