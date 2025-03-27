import 'package:flutter/material.dart';
import 'package:new_test/audio_processor.dart';
import 'package:permission_handler/permission_handler.dart';


class RecordPage extends StatefulWidget {
  final AudioService audioService;
  const RecordPage({super.key, required this.title, required this.audioService});
  final String title;


  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {

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
                icon: Icon(
                  widget.audioService.isRecording ? Icons.stop : Icons.mic,
                  size: 40,
                  color: widget.audioService.isRecording ? Colors.red : Colors.blue,
                ),
                iconSize: 200,
                onPressed: () async {
                  if (widget.audioService.isRecording) {
                    await widget.audioService.stopRecording();
                  } else {
                    await widget.audioService.startRecording();
                  }
                  setState(() {});
                },

            ),
            const SizedBox(height: 20),
            IconButton(
                onPressed: () async {
                  if (widget.audioService.isPlaying) {
                    await widget.audioService.stopAudio();
                  } else {
                    await widget.audioService.playAudio(widget.audioService.audioFiles.last);
                  }
                  setState(() {});
                },
                icon: Icon(
                  widget.audioService.isPlaying ? Icons.stop : Icons.play_arrow,
                  size: 40,
                  color: widget.audioService.isPlaying ? Colors.red : Colors.green,
                )),
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
