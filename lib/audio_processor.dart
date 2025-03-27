import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  List<String> audioFiles = [];

  bool isRecording = false;
  bool isPlaying = false;
  String? audioPath;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    audioPath = '${directory.path}/voice_memo_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: audioPath, codec: Codec.aacADTS);
    isRecording = true;
  }

  Future<void> stopRecording() async {
    if (isRecording) {
      await _recorder.stopRecorder();
      isRecording = false;

      if (audioPath != null && File(audioPath!).existsSync()) {
        audioFiles.add(audioPath!);
      }
    }
  }

  Future<void> playAudio(String path) async {
    if (path.isNotEmpty && File(path).existsSync()) {
      await _player.startPlayer(fromURI: path);
      isPlaying = true;
    }
  }

  Future<void> stopAudio() async {
    await _player.stopPlayer();
    isPlaying = false;
  }

  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
  }
}
