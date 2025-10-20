import 'package:flutter/material.dart';
import '../models/note.dart';
import '../utils/text_formatter.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(Note) onTap;
  final Function(Note) onDelete;
  final Function(Note, bool) onToggleComplete;

  const NoteList({
    super.key,
    required this.notes,
    required this.onTap,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (notes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'Belum ada catatan',
              style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.outline),
            ),
            Text(
              'Tap + untuk menambah catatan baru',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteItem(context, note);
      },
    );
  }

  Widget _buildNoteItem(BuildContext context, Note note) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.9)
        : Colors.black87;

    return Dismissible(
      key: Key(note.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: colorScheme.surface,
              title: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Konfirmasi Hapus',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apakah Anda yakin ingin menghapus catatan ini?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          note.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          note.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.outline,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aksi ini tidak dapat dibatalkan.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text('Batal', style: theme.textTheme.labelLarge),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onDelete(note);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Catatan "${note.title}" dihapus'),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => onDelete(note),

      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: _getColorFromHex(note.color).withOpacity(0.4),
              width: 0.6,
            ),
          ),
          color: _getColorFromHex(note.color).withOpacity(0.15),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Transform.scale(
            scale: 1.3,
            child: Checkbox(
              value: note.isCompleted,
              onChanged: (value) => onToggleComplete(note, value!),
              activeColor: _getColorFromHex(note.color),
              checkColor: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    decoration: note.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorFromHex(note.color),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  note.label,
                  style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 40),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFormattedDescription(
                        context,
                        note.description,
                        isCompleted: note.isCompleted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (note.imagePath != null)
                  Row(
                    children: [
                      Icon(Icons.image, size: 16, color: _getColorFromHex(note.color)),
                      const SizedBox(width: 6),
                      Text(
                        'Ada gambar',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getColorFromHex(note.color),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          onTap: () => onTap(note),
        ),
      ),
    );
  }

  List<Widget> _buildFormattedDescription(BuildContext context, String description,
      {bool isCompleted = false}) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.9)
        : Colors.black87;

    if (description.length > 120) {
      final truncatedText = description.substring(0, 117) + '...';
      return [
        Text(
          truncatedText,
          style: TextStyle(
            decoration:
                isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            fontSize: 14,
            color: textColor,
            height: 1.3,
            fontWeight: FontWeight.w400,
          ),
        ),
      ];
    }

    final formattedWidgets = TextFormatter.buildFormattedText(
      description,
      baseStyle: TextStyle(
        decoration:
            isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
        fontSize: 14,
        color: textColor,
        height: 1.3,
        fontWeight: FontWeight.w400,
      ),
    );

    if (formattedWidgets.length > 3) {
      return [
        ...formattedWidgets.take(2),
        Text(
          '...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ];
    }

    return formattedWidgets;
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) hexColor = "FF$hexColor";
    return Color(int.parse("0x$hexColor"));
  }
}
