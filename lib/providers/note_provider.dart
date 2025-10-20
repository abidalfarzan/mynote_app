import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../database/database_helper.dart';

class NoteProvider with ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _notes = await DatabaseHelper().getNotes();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading notes: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addNote(String title, String description) async {
    final newNote = Note(
      title: title,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await DatabaseHelper().insertNote(newNote);
    newNote.id = id;
    _notes.insert(0, newNote);
    notifyListeners();
  }

  Future<void> updateNote(Note note, String title, String description) async {
    final updatedNote = Note(
      id: note.id,
      title: title,
      description: description,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
    );

    await DatabaseHelper().updateNote(updatedNote);
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }

  Future<void> deleteNote(int id) async {
    await DatabaseHelper().deleteNote(id);
    _notes.removeWhere((note) => note.id == id);
    notifyListeners();
  }
}
