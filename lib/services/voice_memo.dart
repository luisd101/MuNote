import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceMemo {
  final String id;
  final String audioUrl;
  final String notes;
  final DateTime created;
  final bool isLocal;

  VoiceMemo({
    required this.id,
    required this.audioUrl,
    required this.notes,
    required this.created,
    this.isLocal = false
  });

  Map<String, dynamic> toMap() {
    return {
      'audioUrl': audioUrl,
      'notes': notes,
      'created': FieldValue.serverTimestamp(),
    };
  }

  factory VoiceMemo.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return VoiceMemo(
      id: doc.id,
      audioUrl: data['audioUrl'] as String,
      notes: data['notes'] as String,
      created: (data['created'] as Timestamp).toDate(),
      isLocal: false
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': audioUrl,
      'notes': notes,
      'created': created.millisecondsSinceEpoch,
    };
  }

  /// Construct a VoiceMemo from a local JSON entry.
  factory VoiceMemo.fromJson(Map<String, dynamic> json) {
    return VoiceMemo(
      id: json['created'].toString(),
      audioUrl: json['filePath'] as String,
      notes: json['notes'] as String,
      created: DateTime.fromMillisecondsSinceEpoch(json['created'] as int),
      isLocal: true,
    );
  }
}
