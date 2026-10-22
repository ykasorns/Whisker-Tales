/// The seam to a cloud save slot (Play Games Services saved games in the
/// app, D-017, T-023). One slot holds the whole Save v3 document as text.
abstract class CloudStore {
  /// Signed in and switched on. Never asks for anything beyond the
  /// platform's own account.
  Future<bool> available();

  /// The saved text, or null when this account has no save yet. Throws when
  /// the slot cannot be read — never confuse "unreadable" with "empty", or a
  /// device would overwrite real progress.
  Future<String?> read();

  Future<void> write(String data);
}

/// No cloud: the game is local only. The default.
class NoCloudStore implements CloudStore {
  const NoCloudStore();
  @override
  Future<bool> available() async => false;
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String data) async {}
}
