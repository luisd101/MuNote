import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  List<String> audioFiles = []; // Local file paths
  List<String> remoteMemoUrls = []; // Firebase Storage URLs

  bool isRecording = false;
  bool isPlaying = false;
  String? audioPath;
  String? currentlyPlayingUrl;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    await _loadRemoteMemos(); // Load existing memos when initializing
  }

  // Load memos from Firebase Storage
  Future<void> _loadRemoteMemos() async {
    try {
      final ref = _storage.ref().child('voice_memos');
      final result = await ref.listAll();

      remoteMemoUrls = await Future.wait(
        result.items.map((item) => item.getDownloadURL()),
      );
    } catch (e) {
      print('Error loading remote memos: $e');
    }
  }

  // Upload audio file to Firebase Storage
  Future<String?> uploadCurrentRecording() async {
    if (audioPath == null || !File(audioPath!).existsSync()) return null;

    try {
      final audioFile = File(audioPath!);
      final timestamp = (DateTime.now());
      final fileName = 'voice_memo_$timestamp.aac';

      final ref = _storage.ref().child('voice_memos').child(fileName);
      await ref.putFile(audioFile);

      // Get the download URL and add to our list
      final downloadUrl = await ref.getDownloadURL();
      remoteMemoUrls.add(downloadUrl);

      return downloadUrl;
    } catch (e) {
      print('Error uploading audio file: $e');
      return null;
    }
  }

  // Delete memo from Firebase Storage
  Future<bool> deleteRemoteMemo(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      remoteMemoUrls.remove(url);
      return true;
    } catch (e) {
      print('Error deleting memo: $e');
      return false;
    }
  }

  Future<void> startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    audioPath = '${directory.path}/voice_memo_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(toFile: audioPath, codec: Codec.aacADTS);
    isRecording = true;
  }

  Future<String?> stopRecording() async {
    if (!isRecording) return null;

    await _recorder.stopRecorder();
    isRecording = false;

    if (audioPath != null && File(audioPath!).existsSync()) {
      audioFiles.add(audioPath!);
      uploadCurrentRecording();
      return audioPath;
    }
    return null;
  }

  Future<void> playAudio(String path) async {
    if (path.isEmpty) return;
    currentlyPlayingUrl = path;
    if (path.startsWith('http')) {
      // Playing from Firebase URL
      await _player.startPlayer(fromURI: path);
    } else if (File(path).existsSync()) {
      // Playing from local file
      await _player.startPlayer(fromURI: path);
    }
    isPlaying = true;
  }

  Future<void> stopAudio() async {
    await _player.stopPlayer();
    isPlaying = false;
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
  }
}