import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
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

  StreamSubscription<User?>? _authSub;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _loadRemoteMemos();
      }
      else {
        remoteMemoUrls.clear();
      }
    });

  }

  // Load memos from Firebase Storage
  Future<void> _loadRemoteMemos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final ref = _storage.ref().child('voice_memos').child(user.uid);
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
    final path = audioPath;
    if (path == null || !File(path).existsSync()) return null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final file = File(path);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_memo_$ts.aac';

      // → include UID in the path
      final ref = _storage
          .ref()
          .child('voice_memos')
          .child(user.uid)
          .child(fileName);

      await ref.putFile(file);
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