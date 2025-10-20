import 'package:flutter/material.dart';
import 'package:todo_app/screens/finished_note_screen.dart';
import '../models/note.dart';
import '../database/database_helper.dart';
import '../widgets/note_list.dart';
import '../widgets/loading_indicator.dart';
import 'add_edit_note_screen.dart';
import 'note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const HomeScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  List<Note> _getActiveNotes() {
    return _notes.where((n) => !n.isCompleted).toList();
  }


  Future<void> _loadNotes() async {
    print('🔄 Loading notes...');
    setState(() {
      _isLoading = true;
    });

    try {
      // Debug: Print database info sebelum load
      await _databaseHelper.printDatabaseInfo();

      final notes = await _databaseHelper.getNotes();

      setState(() {
        _notes = notes;
        _isLoading = false;
      });

      print('✅ Successfully loaded ${notes.length} notes');
      print(
          '📋 Notes loaded: ${notes.map((n) => '${n.id}: ${n.title}').toList()}');
    } catch (e) {
      print('❌ Error loading notes: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Gagal memuat catatan');
    }
  }

  void _addNote() async {
    print('➕ Adding new note...');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEditNoteScreen(),
      ),
    );

    if (result != null && mounted) {
      try {
        final newNote = Note(
          title: result['title'] ?? 'No Title',
          description: result['description'] ?? 'No Description',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          label: result['label'] ?? 'Umum',
          color: result['color'] ?? '#FF9800',
          imagePath: result['imagePath'],
          link: result['link'],
        );

        print('💾 Attempting to save note: ${newNote.title}');
        print('💾 Note data: ${newNote.toMap()}');

        final id = await _databaseHelper.insertNote(newNote);
        newNote.id = id;

        print('✅ Note saved with ID: $id');

        // Verifikasi penyimpanan dengan memuat ulang dari database
        await _loadNotes();

        _showSuccess('✅ Catatan berhasil ditambahkan');

        // Debug: Print database info
        await _databaseHelper.printDatabaseInfo();
      } catch (e) {
        print('❌ Error adding note: $e');
        _showError('Gagal menambah catatan: $e');
      }
    }
  }

  void _viewNote(Note note) async {
    print('👁️ Viewing note: ${note.title}');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(note: note),
      ),
    );

    // Jika user memilih edit dari detail screen
    if (result == 'edit' && mounted) {
      _editNote(note);
    }
    // Jika catatan dihapus dari detail screen
    else if (result == 'deleted' && mounted) {
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      _showSuccess('🗑️ Catatan "${note.title}" dihapus');
    }

    // Refresh notes setelah kembali dari detail screen
    // untuk memperbarui checklist yang mungkin sudah diubah
    if (mounted) {
      _loadNotes();
    }
  }

  void _editNote(Note note) async {
    print('✏️ Editing note: ${note.title}');
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditNoteScreen(note: note),
      ),
    );

    if (result != null && mounted) {
      try {
        final updatedNote = Note(
          id: note.id,
          title: result['title'] ?? note.title,
          description: result['description'] ?? note.description,
          createdAt: note.createdAt,
          updatedAt: DateTime.now(),
          label: result['label'] ?? note.label,
          color: result['color'] ?? note.color,
          imagePath: result['imagePath'] ?? note.imagePath,
          isCompleted: note.isCompleted,
        );

        await _databaseHelper.updateNote(updatedNote);

        setState(() {
          final index = _notes.indexWhere((n) => n.id == note.id);
          if (index != -1) {
            _notes[index] = updatedNote;
          }
        });

        _showSuccess('✅ Catatan berhasil diperbarui');
      } catch (e) {
        print('❌ Error updating note: $e');
        _showError('Gagal memperbarui catatan: $e');
      }
    }
  }

  void _deleteNote(Note note) async {
    try {
      await _databaseHelper.deleteNote(note.id!);

      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });

      if (mounted) {
        _showSuccess('🗑️ Catatan dihapus');
      }
    } catch (e) {
      print('❌ Error deleting note: $e');
      if (mounted) {
        _showError('Gagal menghapus catatan: $e');
      }
    }
  }

  void _toggleComplete(Note note, bool isCompleted) async {
    try {
      final updatedNote = Note(
        id: note.id,
        title: note.title,
        description: note.description,
        createdAt: note.createdAt,
        updatedAt: DateTime.now(),
        isCompleted: isCompleted,
        imagePath: note.imagePath,
        label: note.label,
        color: note.color,
      );  

      await _databaseHelper.updateNote(updatedNote);  

      setState(() {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = updatedNote;
        } 

        // ✅ Tambahin notif di sini
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isCompleted ? Colors.green : Colors.orange,
            content: Text(
              isCompleted
                  ? '🎉 Catatan "${note.title}" telah diselesaikan!'
                  : '🔄 Catatan "${note.title}" dikembalikan ke daftar aktif.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } catch (e) {
      print('❌ Error toggling complete: $e');
      if (mounted) {
        _showError('Gagal mengubah status: $e');
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Hapus Semua Catatan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apakah Anda yakin ingin menghapus SEMUA catatan (${_notes.length} catatan)?',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aksi ini tidak dapat dibatalkan dan akan menghapus semua data catatan Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _deleteAllNotes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus Semua'),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllNotes() async {
    try {
      // Simpan jumlah catatan untuk pesan sukses
      final deletedCount = _notes.length;

      // Hapus semua catatan dari database
      for (var note in _notes) {
        await _databaseHelper.deleteNote(note.id!);
      }

      // Update UI
      setState(() {
        _notes.clear();
      });

      if (mounted) {
        _showSuccess('🗑️ $deletedCount catatan berhasil dihapus');
      }
    } catch (e) {
      print('❌ Error deleting all notes: $e');
      if (mounted) {
        _showError('Gagal menghapus semua catatan: $e');
      }
    }
  }

  void _deleteCompletedNotes() async {
    try {
      // Cari catatan yang sudah selesai
      final completedNotes = _notes.where((note) => note.isCompleted).toList();

      if (completedNotes.isEmpty) {
        _showError('Tidak ada catatan yang sudah selesai');
        return;
      }

      // Konfirmasi
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text('Hapus Catatan Selesai'),
              ],
            ),
            content: Text(
              'Hapus ${completedNotes.length} catatan yang sudah selesai?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          );
        },
      );

      if (shouldDelete == true) {
        // Hapus dari database
        for (var note in completedNotes) {
          await _databaseHelper.deleteNote(note.id!);
        }

        // Update UI
        setState(() {
          _notes.removeWhere((note) => note.isCompleted);
        });

        if (mounted) {
          _showSuccess('🗑️ ${completedNotes.length} catatan selesai dihapus');
        }
      }
    } catch (e) {
      print('❌ Error deleting completed notes: $e');
      if (mounted) {
        _showError('Gagal menghapus catatan selesai: $e');
      }
    }
  }


  // Tampilan Utama
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aplikasi Catatan Saya',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFFFB342),
        foregroundColor: Colors.white,
        elevation: 2,
        toolbarHeight: 60,
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: Colors.white,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Ganti Tema',
          ),
          if (_notes.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 28),
              iconSize: 28,
              onSelected: (value) {
                switch (value) {
                  case 'delete_all':
                    _showDeleteAllConfirmation();
                    break;
                  case 'view_completed':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FinishedNoteScreen(
                          notes: _notes,
                          onToggleComplete: _toggleComplete,
                          onDeleteCompleted: _deleteCompletedNotes,
                          onRefresh: _loadNotes,
                        ),
                      ),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'view_completed',
                  height: 50,
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFFFFB342), size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Lihat yang Selesai',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete_all',
                  height: 50,
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, color: Colors.red, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Hapus Semua',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            iconSize: 28,
            onPressed: _loadNotes,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add, size: 80, color: Colors.grey),
                      SizedBox(height: 24),
                      Text(
                        'Belum ada catatan',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap tombol + untuk menambah catatan baru',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotes,
                  child:
                    // Tampilkan daftar catatan
                    NoteList(
                      notes: _getActiveNotes(),
                      onTap: _viewNote,
                      onDelete: _deleteNote,
                      onToggleComplete: _toggleComplete,
                    ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNote,
        backgroundColor: const Color(0xFFFFB342), // warna asli seed
        foregroundColor: Colors.white,
        tooltip: 'Tambah Catatan',
        icon: const Icon(Icons.add, size: 28),
        label: const Text(
          'Tambah',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
      ),
    );
  }
}
