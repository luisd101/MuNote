import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

import 'package:myapp/services/voice_memo.dart';

class AudioService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'memos',
  );

  List<String> audioFiles = [];       // Local file paths (just in case)
  List<VoiceMemo> memos = [];         // Remote or local memos

  bool isRecording = false;
  bool isPlaying = false;
  String? audioPath;
  String? currentlyPlayingUrl;

  StreamSubscription<User?>? _authSub;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();

    // Watch auth: if signed in, load cloud memos; otherwise load local ones
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        loadRemoteMemos();
      } else {
        loadLocalMemos().then((local) => memos = local);
      }
    });
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    await _authSub?.cancel();
  }

  /// Starts recording to a timestamped .aac file in documents dir
  Future<void> startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    audioPath = '${dir.path}/voice_memo_${DateTime.now().millisecondsSinceEpoch}.aac';
    await _recorder.startRecorder(
      toFile: audioPath,
      codec: Codec.aacADTS,
    );
    isRecording = true;
  }

  /// Stops recorder and adds file to audioFiles list
  Future<void> stopRecording() async {
    if (!isRecording) return;
    await _recorder.stopRecorder();
    isRecording = false;

    if (audioPath != null && File(audioPath!).existsSync()) {
      audioFiles.add(audioPath!);
    }
  }

  /// Uploads to Firebase if signed in; otherwise saves locally.
  Future<String?> uploadCurrentRecording({String notes = ''}) async {
    if (audioPath == null || !File(audioPath!).existsSync()) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // No auth → save to local storage
      final ok = await saveLocalMemo(notes: notes);
      if (ok) {
        memos = await loadLocalMemos();
      }
      return null;
    }

    try {
      final file = File(audioPath!);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'voice_memo_$ts.aac';
      final ref = _storage
          .ref()
          .child('voice_memos')
          .child(user.uid)
          .child(fileName);

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await _db
          .collection('memos')
          .doc(user.uid)
          .collection('memos')
          .add({
        'audioUrl': downloadUrl,
        'notes': notes,
        'created': FieldValue.serverTimestamp(),
      });

      await loadRemoteMemos();
      return downloadUrl;
    } catch (e) {
      print('Error uploading and saving memo: $e');
      return null;
    }
  }

  /// Remote memos from Firestore
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

  /// Local directory for saving offline memos
  Future<Directory> get _localMemosDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/local_memos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Save the last recording into local_memos + index JSON
  Future<bool> saveLocalMemo({String notes = ''}) async {
    if (audioPath == null || !File(audioPath!).existsSync()) return false;
    final dir = await _localMemosDir;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final newFile = File('${dir.path}/voice_memo_$ts.aac');
    await File(audioPath!).copy(newFile.path);

    final indexFile = File('${dir.path}/memos_index.json');
    List<Map<String, dynamic>> index = [];
    if (await indexFile.exists()) {
      final raw = await indexFile.readAsString();
      index = List<Map<String, dynamic>>.from(jsonDecode(raw));
    }

    index.add({
      'filePath': newFile.path,
      'notes': notes,
      'created': ts,
    });

    await indexFile.writeAsString(jsonEncode(index));
    return true;
  }

  /// Load all locally saved memos
  Future<List<VoiceMemo>> loadLocalMemos() async {
    final dir = await _localMemosDir;
    final indexFile = File('${dir.path}/memos_index.json');
    if (!await indexFile.exists()) return [];

    final raw = await indexFile.readAsString();
    final List<Map<String, dynamic>> index =
    List<Map<String, dynamic>>.from(jsonDecode(raw));

    return index.map((m) {
      return VoiceMemo(
        id: m['created'].toString(),
        audioUrl: m['filePath'],
        notes: m['notes'],
        created: DateTime.fromMillisecondsSinceEpoch(m['created']),
        isLocal: true,
      );
    }).toList();
  }

  /// Play from a local path or a remote URL
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

  /// Deletes either a cloud memo or a local memo
  Future<bool> deleteMemo(VoiceMemo memo) async {
    try {
      if (memo.isLocal == true || !memo.audioUrl.startsWith('http')) {
        // --- Local deletion ---
        final f = File(memo.audioUrl);
        if (await f.exists()) await f.delete();

        // Update index JSON
        final dir = await _localMemosDir;
        final indexFile = File('${dir.path}/memos_index.json');
        if (await indexFile.exists()) {
          final raw = await indexFile.readAsString();
          final List<Map<String, dynamic>> index =
          List<Map<String, dynamic>>.from(jsonDecode(raw));
          index.removeWhere((e) => e['filePath'] == memo.audioUrl);
          await indexFile.writeAsString(jsonEncode(index));
        }

      } else {
        // --- Remote deletion ---
        final ref = _storage.refFromURL(memo.audioUrl);
        await ref.delete();

        await _db
            .collection('memos')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('memos')
            .doc(memo.id)
            .delete();
      }

      memos.removeWhere((m) => m.id == memo.id);
      return true;
    } catch (e) {
      print('Error deleting memo: $e');
      return false;
    }
  }
}
