import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:myapp/services/voice_memo.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'memos',
  );


  List<String> audioFiles = [];       // Local file paths
  List<VoiceMemo> memos = [];         // Loaded memos (with notes)

  bool isRecording = false;
  bool isPlaying = false;
  String? audioPath;
  String? currentlyPlayingUrl;

  StreamSubscription<User?>? _authSub;

  Future<void> init() async {
    // Open recorder & player
    await _recorder.openRecorder();
    await _player.openPlayer();

    // Listen to auth changes to load/clear memos
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadRemoteMemos();
      } else {
        memos.clear();
      }
    });
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    await _authSub?.cancel();
  }

  // Start recording to a local file
  Future<void> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    audioPath = '${dir.path}/voice_memo_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(
      toFile: audioPath,
      codec: Codec.aacADTS,
    );
    isRecording = true;
  }

  // Stop recording and keep the file locally
  Future<void> stopRecording() async {
    if (!isRecording) return;
    await _recorder.stopRecorder();
    isRecording = false;

    if (audioPath != null && File(audioPath!).existsSync()) {
      audioFiles.add(audioPath!);
    }
  }

  /// Uploads the last recorded file AND saves its notes in Firestore.
  Future<String?> uploadCurrentRecording({String notes = ''}) async {
    if (audioPath == null || !File(audioPath!).existsSync()) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final file = File(audioPath!);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_memo_$ts.aac';

      // Upload to user-scoped Storage path
      final ref = _storage
          .ref()
          .child('voice_memos')
          .child(user.uid)
          .child(fileName);
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Create Firestore doc with URL + notes + timestamp
      await _db
          .collection('memos')
          .doc(user.uid)
          .collection('memos')
          .add({
        'audioUrl': downloadUrl,
        'notes': notes,
        'created': FieldValue.serverTimestamp(),
      });

      // Reload memos so UI reflects new entry
      await loadRemoteMemos();
      return downloadUrl;
    } catch (e) {
      print('Error uploading and saving memo: $e');
      return null;
    }
  }

  /// Loads all memos (with notes) from Firestore
  Future<void> loadRemoteMemos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await _db
        .collection('memos')
        .doc(user.uid)
        .collection('memos')
        .orderBy('created', descending: true)
        .get();

    memos = snap.docs.map((d) => VoiceMemo.fromDoc(d)).toList();
  }

  // Play local file or remote URL
  Future<void> playAudio(String path) async {
    if (path.isEmpty) return;
    currentlyPlayingUrl = path;
    await _player.startPlayer(fromURI: path);
    isPlaying = true;
  }

  Future<void> stopAudio() async {
    await _player.stopPlayer();
    isPlaying = false;
  }

  /// Deletes a memo from Storage and Firestore
  Future<bool> deleteMemo(VoiceMemo memo) async {
    try {
      // Delete Storage object
      final ref = _storage.refFromURL(memo.audioUrl);
      await ref.delete();

      // Delete Firestore doc
      await _db
          .collection('memos')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('memos')
          .doc(memo.id)
          .delete();

      // Update local list
      memos.removeWhere((m) => m.id == memo.id);
      return true;
    } catch (e) {
      print('Error deleting memo: $e');
      return false;
    }
  }
}
