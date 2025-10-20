import 'package:flutter/material.dart';
import 'package:todo_app/screens/note_detail_screen.dart';
import '../models/note.dart';
import '../widgets/note_list.dart';

class FinishedNoteScreen extends StatefulWidget {
  final List<Note> notes;
  final Function(Note, bool) onToggleComplete;
  final VoidCallback onDeleteCompleted;
  final Future<void> Function() onRefresh;

  const FinishedNoteScreen({
    Key? key,
    required this.notes,
    required this.onToggleComplete,
    required this.onDeleteCompleted,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<FinishedNoteScreen> createState() => _FinishedNoteScreen();
}

class _FinishedNoteScreen extends State<FinishedNoteScreen> {

  @override
  Widget build(BuildContext context) {
    final completedNotes = widget.notes.where((n) => n.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tugas Selesai',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFFB342),
        foregroundColor: Colors.white,
        actions: [
          if (completedNotes.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete_completed') {
                  widget.onDeleteCompleted();
                  Navigator.pop(context); // langsung balik ke homepage
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete_completed',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Hapus Semua Tugas Selesai'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: completedNotes.isEmpty
          ? const Center(
              child: Text(
                'Belum ada tugas selesai',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: NoteList(
              notes: completedNotes,
              onTap: (note) async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteDetailScreen(note: note),
                  ),
                );
                widget.onRefresh();
              },
              onDelete: (note) {
                // opsional: implement single-delete di sini nanti
              },
              onToggleComplete: (note, isCompleted) async {
                widget.onToggleComplete(note, false);
                await widget.onRefresh();
                if (mounted) Navigator.pop(context);
              },
            ),
          )
    );
  }
}