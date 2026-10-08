/// The **file-name convention** for saved designs, in one pure place.
///
/// Why this tiny class exists: the PNG name is derivable from the design id
/// (`design_<id>.png`). That means the album can rebuild a missing picture
/// reference *without* any extra bookkeeping — if the app was killed between
/// writing the file and writing the index, the name is still recoverable.
///
/// No Flutter, no `dart:io`, no plugins → importable by models, repositories
/// and tests alike.
abstract final class DesignFiles {
  /// Files that were being written when the app closed. They are deleted at
  /// startup; a half-written temp file must never be mistaken for a design.
  static const String tempPrefix = '.tmp_';

  static const String prefix = 'design_';
  static const String extension = '.png';

  /// `abc123` → `design_abc123.png`
  static String nameFor(String designId) =>
      '$prefix$designId$extension';

  /// `design_abc123.png` → `abc123`; anything else → `null`.
  static String? idFrom(String fileName) {
    if (!fileName.startsWith(prefix) || !fileName.endsWith(extension)) {
      return null;
    }
    final String id = fileName.substring(
      prefix.length,
      fileName.length - extension.length,
    );
    return id.isEmpty ? null : id;
  }

  static bool isTemp(String fileName) => fileName.startsWith(tempPrefix);
}
