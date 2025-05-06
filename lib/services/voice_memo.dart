import 'package:cloud_firestore/cloud_firestore.dart';

class VoiceMemo {
  final String id;
  final String audioUrl;
  final String notes;
  final DateTime created;

  VoiceMemo({
    required this.id,
    required this.audioUrl,
    required this.notes,
    required this.created,
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
    );
  }
}
