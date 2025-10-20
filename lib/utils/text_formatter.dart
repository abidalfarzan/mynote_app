import 'package:flutter/material.dart';

class TextFormatter {
  /// Menambahkan checklist item pada posisi cursor
  static String addChecklistItem(String text, int cursorPosition,
      {bool checked = false}) {
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    // Cari baris terakhir sebelum cursor
    final lines = beforeCursor.split('\n');
    final lastLine = lines.isNotEmpty ? lines.last : '';

    // Jika cursor di akhir baris kosong atau di awal, langsung tambahkan checklist
    String checklistItem = checked ? '☑️ ' : '☐ ';

    if (lastLine.trim().isEmpty) {
      return beforeCursor + checklistItem + afterCursor;
    } else {
      return beforeCursor + '\n' + checklistItem + afterCursor;
    }
  }

  /// Menambahkan numbered list pada posisi cursor
  static String addNumberedItem(String text, int cursorPosition) {
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    // Cari nomor terakhir dalam numbered list
    final lines = beforeCursor.split('\n');
    int nextNumber = 1;

    // Cari nomor terakhir dari baris-baris sebelumnya
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      final numberMatch = RegExp(r'^(\d+)\.\s').firstMatch(line);
      if (numberMatch != null) {
        nextNumber = int.parse(numberMatch.group(1)!) + 1;
        break;
      } else if (line.isNotEmpty && !line.startsWith(RegExp(r'^\d+\.\s'))) {
        // Jika baris tidak kosong dan bukan numbered list, mulai dari 1
        break;
      }
    }

    String numberedItem = '$nextNumber. ';

    if (lines.last.trim().isEmpty) {
      return beforeCursor + numberedItem + afterCursor;
    } else {
      return beforeCursor + '\n' + numberedItem + afterCursor;
    }
  }

  /// Toggle status checklist pada baris yang mengandung cursor
  static String toggleChecklistAtCursor(String text, int cursorPosition) {
    final lines = text.split('\n');
    int currentLine = 0;
    int charCount = 0;

    // Cari baris yang mengandung cursor
    for (int i = 0; i < lines.length; i++) {
      if (charCount + lines[i].length >= cursorPosition) {
        currentLine = i;
        break;
      }
      charCount += lines[i].length + 1; // +1 untuk newline
    }

    if (currentLine < lines.length) {
      final line = lines[currentLine];

      // Check jika baris ini adalah checklist
      if (line.contains('☐ ')) {
        lines[currentLine] = line.replaceFirst('☐ ', '☑️ ');
      } else if (line.contains('☑️ ')) {
        lines[currentLine] = line.replaceFirst('☑️ ', '☐ ');
      }
    }

    return lines.join('\n');
  }

  /// Render text dengan formatting yang sesuai untuk display
  static List<Widget> buildFormattedText(String text, {TextStyle? baseStyle}) {
    final lines = text.split('\n');
    List<Widget> widgets = [];

    for (String line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Checklist items
      if (line.contains('☐ ') || line.contains('☑️ ')) {
        final isChecked = line.contains('☑️ ');
        final cleanText = line.replaceAll(RegExp(r'☐ |☑️ '), '').trim();

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 22,
                  color: isChecked ? Colors.green : Colors.grey[600],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cleanText,
                    style: (baseStyle ?? const TextStyle()).copyWith(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Numbered list items
      else if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        final match = RegExp(r'^(\d+)\.\s(.*)').firstMatch(line.trim());
        if (match != null) {
          final number = match.group(1)!;
          final text = match.group(2)!;

          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$number.',
                      style: (baseStyle ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: (baseStyle?.fontSize ?? 14) + 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: baseStyle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      // Regular text
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: baseStyle,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  /// Hitung posisi cursor baru setelah menambahkan checklist/numbering
  static int getNewCursorPosition(
      String originalText, String newText, int originalPosition) {
    // Sederhana: posisi cursor setelah item yang baru ditambahkan
    final difference = newText.length - originalText.length;
    return originalPosition + difference;
  }

  /// Handle enter key press untuk auto-continue numbering atau checklist
  static Map<String, dynamic> handleEnterPress(
      String text, int cursorPosition) {
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);

    // Cari baris saat ini
    final lines = beforeCursor.split('\n');
    final currentLine = lines.isNotEmpty ? lines.last : '';

    // Check jika baris saat ini adalah numbered list
    final numberMatch =
        RegExp(r'^(\d+)\.\s(.*)').firstMatch(currentLine.trim());
    if (numberMatch != null) {
      final currentNumber = int.parse(numberMatch.group(1)!);
      final currentText = numberMatch.group(2)!.trim();

      // Jika baris kosong, hapus numbering
      if (currentText.isEmpty) {
        final newBeforeCursor =
            beforeCursor.substring(0, beforeCursor.lastIndexOf(currentLine));
        return {
          'newText': newBeforeCursor + afterCursor,
          'newCursorPosition': newBeforeCursor.length,
          'shouldUpdate': true,
        };
      } else {
        // Lanjutkan dengan nomor berikutnya
        final nextNumber = currentNumber + 1;
        final newText = beforeCursor + '\n$nextNumber. ' + afterCursor;
        return {
          'newText': newText,
          'newCursorPosition': beforeCursor.length + '\n$nextNumber. '.length,
          'shouldUpdate': true,
        };
      }
    }

    // Check jika baris saat ini adalah checklist
    final checklistMatch =
        RegExp(r'^(☐|☑️)\s(.*)').firstMatch(currentLine.trim());
    if (checklistMatch != null) {
      final currentText = checklistMatch.group(2)!.trim();

      // Jika baris kosong, hapus checklist
      if (currentText.isEmpty) {
        final newBeforeCursor =
            beforeCursor.substring(0, beforeCursor.lastIndexOf(currentLine));
        return {
          'newText': newBeforeCursor + afterCursor,
          'newCursorPosition': newBeforeCursor.length,
          'shouldUpdate': true,
        };
      } else {
        // Lanjutkan dengan checklist baru (unchecked)
        final newText = beforeCursor + '\n☐ ' + afterCursor;
        return {
          'newText': newText,
          'newCursorPosition': beforeCursor.length + '\n☐ '.length,
          'shouldUpdate': true,
        };
      }
    }

    // Baris normal, tidak ada special handling
    return {
      'shouldUpdate': false,
    };
  }

  /// Toggle checklist pada posisi tertentu (untuk widget interaktif)
  static String toggleChecklistAtPosition(String text, int lineIndex) {
    final lines = text.split('\n');

    if (lineIndex >= 0 && lineIndex < lines.length) {
      final line = lines[lineIndex];

      if (line.contains('☐ ')) {
        lines[lineIndex] = line.replaceFirst('☐ ', '☑️ ');
      } else if (line.contains('☑️ ')) {
        lines[lineIndex] = line.replaceFirst('☑️ ', '☐ ');
      }
    }

    return lines.join('\n');
  }

  /// Render text dengan formatting interaktif untuk detail view
  static List<Widget> buildInteractiveFormattedText(
    String text, {
    TextStyle? baseStyle,
    Function(int)? onChecklistToggle,
  }) {
    final lines = text.split('\n');
    List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Checklist items with interactive checkbox
      if (line.contains('☐ ') || line.contains('☑️ ')) {
        final isChecked = line.contains('☑️ ');
        final cleanText = line.replaceAll(RegExp(r'☐ |☑️ '), '').trim();

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onChecklistToggle != null
                      ? () => onChecklistToggle(i)
                      : null,
                  child: Icon(
                    isChecked ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 20,
                    color: isChecked ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cleanText,
                    style: (baseStyle ?? const TextStyle()).copyWith(
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      color: isChecked ? Colors.grey : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      // Numbered list items
      else if (RegExp(r'^\d+\.\s').hasMatch(line.trim())) {
        final match = RegExp(r'^(\d+)\.\s(.*)').firstMatch(line.trim());
        if (match != null) {
          final number = match.group(1)!;
          final text = match.group(2)!;

          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '$number.',
                      style: (baseStyle ?? const TextStyle()).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      text,
                      style: baseStyle,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
      // Regular text
      else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              line,
              style: baseStyle,
            ),
          ),
        );
      }
    }

    return widgets;
  }
}
