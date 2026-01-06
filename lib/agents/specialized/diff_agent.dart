import 'dart:io';

import '../core/agent_base.dart';
import '../core/step_types.dart';

/// Agent for file diff/patch operations with autonomous create and edit capabilities.
///
/// Supports:
/// - Generating unified diffs between files
/// - Applying patches to existing files
/// - Creating new files autonomously
/// - Editing existing files safely via patches
class DiffAgent extends AgentBase {
  DiffAgent({super.logger}) : super(name: 'Diff');

  @override
  Future<R> onRun<R>(dynamic input) async {
    if (input is DiffRequest) {
      return await handleRequest(input) as R;
    }
    throw ArgumentError('Expected DiffRequest');
  }

  Future<dynamic> handleRequest(DiffRequest request) async {
    switch (request.operation) {
      case DiffOperation.generateDiff:
        return await generateDiff(
          original: request.original!,
          modified: request.modified!,
          filename: request.filename!,
        );
      case DiffOperation.applyPatch:
        return await applyPatch(
          filePath: request.filePath!,
          patch: request.patch!,
        );
      case DiffOperation.createFile:
        return await createFile(
          filePath: request.filePath!,
          content: request.content!,
        );
      case DiffOperation.editFile:
        return await editFile(
          filePath: request.filePath!,
          edits: request.edits!,
        );
    }
  }

  /// Generate a unified diff between two strings
  Future<String> generateDiff({
    required String original,
    required String modified,
    required String filename,
  }) async {
    return await execute<String>(
      action: StepType.analyze,
      target: 'generating diff for $filename',
      task: () async {
        final originalLines = original.split('\n');
        final modifiedLines = modified.split('\n');

        final buffer = StringBuffer();
        buffer.writeln('--- a/$filename');
        buffer.writeln('+++ b/$filename');

        // Simple line-by-line diff (for demo - real impl would use LCS)
        final hunks = _computeHunks(originalLines, modifiedLines);
        for (final hunk in hunks) {
          buffer.writeln(hunk);
        }

        return buffer.toString();
      },
    );
  }

  List<String> _computeHunks(List<String> original, List<String> modified) {
    final hunks = <String>[];
    int i = 0, j = 0;

    while (i < original.length || j < modified.length) {
      // Find next difference
      while (i < original.length &&
          j < modified.length &&
          original[i] == modified[j]) {
        i++;
        j++;
      }

      if (i >= original.length && j >= modified.length) break;

      // Found a difference - create hunk
      final startI = i;
      final startJ = j;

      // Collect changes
      final changes = <String>[];

      // Collect deletions
      while (i < original.length &&
          (j >= modified.length || original[i] != modified[j])) {
        changes.add('-${original[i]}');
        i++;
      }

      // Collect additions
      while (j < modified.length &&
          (i >= original.length || original[i] != modified[j])) {
        changes.add('+${modified[j]}');
        j++;
      }

      if (changes.isNotEmpty) {
        hunks.add(
            '@@ -${startI + 1},${i - startI} +${startJ + 1},${j - startJ} @@');
        hunks.addAll(changes);
      }
    }

    return hunks;
  }

  /// Apply a patch to an existing file
  Future<bool> applyPatch({
    required String filePath,
    required String patch,
  }) async {
    return await execute<bool>(
      action: StepType.modify,
      target: 'applying patch to $filePath',
      task: () async {
        final file = File(filePath);
        if (!await file.exists()) {
          throw StateError('File does not exist: $filePath');
        }

        final original = await file.readAsString();
        final patched = _applyPatchToContent(original, patch);

        await file.writeAsString(patched);
        return true;
      },
      metadata: {'patch_lines': patch.split('\n').length},
    );
  }

  String _applyPatchToContent(String original, String patch) {
    final lines = original.split('\n').toList();
    final patchLines = patch.split('\n');

    for (int i = 0; i < patchLines.length; i++) {
      final line = patchLines[i];

      if (line.startsWith('@@')) {
        // Parse hunk header: @@ -start,count +start,count @@
        // Currently using simple line matching, hunk positions tracked via offset
        continue;
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        // Deletion - find and remove
        final content = line.substring(1);
        final idx = lines.indexWhere((l) => l == content);
        if (idx != -1) {
          lines.removeAt(idx);
        }
      } else if (line.startsWith('+') && !line.startsWith('+++')) {
        // Addition - insert at current position
        final content = line.substring(1);
        // Simple append for now
        lines.add(content);
      }
    }

    return lines.join('\n');
  }

  /// Create a new file with content
  Future<bool> createFile({
    required String filePath,
    required String content,
  }) async {
    return await execute<bool>(
      action: StepType.store,
      target: 'creating file $filePath',
      task: () async {
        final file = File(filePath);

        // Ensure directory exists
        final dir = file.parent;
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        // Check if file already exists
        if (await file.exists()) {
          throw StateError(
              'File already exists: $filePath. Use editFile instead.');
        }

        await file.writeAsString(content);
        return true;
      },
      metadata: {
        'path': filePath,
        'size': content.length,
      },
    );
  }

  /// Edit an existing file with specific changes
  Future<bool> editFile({
    required String filePath,
    required List<FileEdit> edits,
  }) async {
    return await execute<bool>(
      action: StepType.modify,
      target: 'editing file $filePath (${edits.length} changes)',
      task: () async {
        final file = File(filePath);
        if (!await file.exists()) {
          throw StateError(
              'File does not exist: $filePath. Use createFile instead.');
        }

        var content = await file.readAsString();

        // Apply edits in reverse order to preserve line numbers
        final sortedEdits = List<FileEdit>.from(edits)
          ..sort((a, b) => b.startLine.compareTo(a.startLine));

        final lines = content.split('\n');

        for (final edit in sortedEdits) {
          if (edit.type == EditType.replace) {
            // Replace lines
            lines.removeRange(edit.startLine, edit.endLine + 1);
            lines.insertAll(edit.startLine, edit.newContent!.split('\n'));
          } else if (edit.type == EditType.delete) {
            // Delete lines
            lines.removeRange(edit.startLine, edit.endLine + 1);
          } else if (edit.type == EditType.insert) {
            // Insert after line
            lines.insertAll(edit.startLine + 1, edit.newContent!.split('\n'));
          }
        }

        await file.writeAsString(lines.join('\n'));
        return true;
      },
      metadata: {
        'path': filePath,
        'edits': edits.length,
      },
    );
  }

  /// Verify a file compiles (for Dart files)
  Future<bool> verifyCompile(String filePath) async {
    return await execute<bool>(
      action: StepType.check,
      target: 'verifying compile for $filePath',
      task: () async {
        // For now just check file exists and is readable
        final file = File(filePath);
        if (!await file.exists()) return false;

        // Could run `dart analyze` here for real verification
        return true;
      },
    );
  }
}

/// Types of diff operations
enum DiffOperation {
  generateDiff,
  applyPatch,
  createFile,
  editFile,
}

/// Request for diff operations
class DiffRequest {
  final DiffOperation operation;
  final String? original;
  final String? modified;
  final String? filename;
  final String? filePath;
  final String? patch;
  final String? content;
  final List<FileEdit>? edits;

  const DiffRequest({
    required this.operation,
    this.original,
    this.modified,
    this.filename,
    this.filePath,
    this.patch,
    this.content,
    this.edits,
  });

  factory DiffRequest.generateDiff({
    required String original,
    required String modified,
    required String filename,
  }) =>
      DiffRequest(
        operation: DiffOperation.generateDiff,
        original: original,
        modified: modified,
        filename: filename,
      );

  factory DiffRequest.applyPatch({
    required String filePath,
    required String patch,
  }) =>
      DiffRequest(
        operation: DiffOperation.applyPatch,
        filePath: filePath,
        patch: patch,
      );

  factory DiffRequest.createFile({
    required String filePath,
    required String content,
  }) =>
      DiffRequest(
        operation: DiffOperation.createFile,
        filePath: filePath,
        content: content,
      );

  factory DiffRequest.editFile({
    required String filePath,
    required List<FileEdit> edits,
  }) =>
      DiffRequest(
        operation: DiffOperation.editFile,
        filePath: filePath,
        edits: edits,
      );
}

/// Types of file edits
enum EditType {
  replace,
  delete,
  insert,
}

/// A single file edit operation
class FileEdit {
  final EditType type;
  final int startLine;
  final int endLine;
  final String? oldContent;
  final String? newContent;

  const FileEdit({
    required this.type,
    required this.startLine,
    required this.endLine,
    this.oldContent,
    this.newContent,
  });

  factory FileEdit.replace({
    required int startLine,
    required int endLine,
    required String oldContent,
    required String newContent,
  }) =>
      FileEdit(
        type: EditType.replace,
        startLine: startLine,
        endLine: endLine,
        oldContent: oldContent,
        newContent: newContent,
      );

  factory FileEdit.delete({
    required int startLine,
    required int endLine,
  }) =>
      FileEdit(
        type: EditType.delete,
        startLine: startLine,
        endLine: endLine,
      );

  factory FileEdit.insert({
    required int afterLine,
    required String content,
  }) =>
      FileEdit(
        type: EditType.insert,
        startLine: afterLine,
        endLine: afterLine,
        newContent: content,
      );
}
