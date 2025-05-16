import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/services/audio_processor.dart';
import 'package:myapp/services/voice_memo.dart';
import 'package:intl/intl.dart';

class LibraryPage extends StatefulWidget {
  final AudioService audioService;
  final String title;

  const LibraryPage({
    super.key,
    required this.title,
    required this.audioService,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  Future<void> _loadMemos() async {
    setState(() => _isLoading = true);
    try {
      await widget.audioService.loadRemoteMemos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading memos: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _deleteMemo(VoiceMemo memo) async {
    setState(() => _isDeleting = true);
    final success = await widget.audioService.deleteMemo(memo);
    setState(() => _isDeleting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memo deleted')),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting memo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final memos = widget.audioService.memos;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMemos,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : memos.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_music, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              'No memos yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Record and save your first memo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: memos.length,
        itemBuilder: (context, index) {
          final memo = memos[index];
          final isPlaying = widget.audioService.isPlaying &&
              widget.audioService.currentlyPlayingUrl == memo.audioUrl;
          final createdAt = memo.created;
          final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt);

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (memo.notes.isNotEmpty) ...[
                    Text(
                      memo.notes,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          isPlaying ? Icons.stop : Icons.play_arrow,
                          color: isPlaying ? Colors.red : Colors.green,
                        ),
                        onPressed: () async {
                          if (isPlaying) {
                            await widget.audioService.stopAudio();
                          } else {
                            await widget.audioService.playAudio(memo.audioUrl);
                          }
                          setState(() {});
                        },
                      ),
                      const Spacer(),
                      if (_isDeleting)
                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteMemo(memo),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
