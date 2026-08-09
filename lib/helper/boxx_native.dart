import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../src/sanitize_filename.dart';
import '../src/storage_key.dart';
import 'boxx_interface.dart';

/// Filesystem implementation used by Android, iOS, Linux, macOS, and Windows.
class BoxxHelper extends BoxxInterface {
  BoxxHelper({
    required super.namespace,
    required super.mode,
    required super.encryptionKey,
    required super.legacyMode,
    required super.legacyEncryptionKey,
  });

  Directory? _baseDirectory;
  Directory? _namespaceDirectory;

  @override
  Future<void> initialize() async {
    if (_namespaceDirectory != null) return;
    _baseDirectory = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(_baseDirectory!.path, 'boxx', storageIdentifier(namespace)),
    );
    await directory.create(recursive: true);
    _namespaceDirectory = directory;
  }

  Future<Directory> get _storageDirectory async {
    await initialize();
    return _namespaceDirectory!;
  }

  Future<File> _recordFile(String key) async => File(
    p.join((await _storageDirectory).path, '${storageIdentifier(key)}.boxx'),
  );

  File? _legacyFile(String key) {
    if (namespace != 'default' || _baseDirectory == null) return null;
    return File(p.join(_baseDirectory!.path, '${sanitizeFilename(key)}.boxx'));
  }

  @override
  Future<void> put(String key, dynamic value) async {
    final file = await _recordFile(key);
    await _writeAtomically(file, codec.encode(key, value));
    final legacy = _legacyFile(key);
    if (legacy != null && await legacy.exists()) {
      await legacy.delete();
    }
    notifyListeners(key);
  }

  @override
  Future<dynamic> get(String key) async {
    final file = await _recordFile(key);
    if (await file.exists()) {
      return codec
          .decode(
            await file.readAsString(),
            expectedKey: key,
            allowLegacy: false,
          )
          .value;
    }

    final legacy = _legacyFile(key);
    if (legacy == null || !await legacy.exists()) return null;
    final decoded = codec.decode(
      await legacy.readAsString(),
      expectedKey: key,
      allowLegacy: true,
      legacyFallbackKey: key,
    );
    await _writeAtomically(file, codec.encode(key, decoded.value));
    await legacy.delete();
    notifyListeners(key);
    return decoded.value;
  }

  @override
  Future<void> delete(String key) async {
    var changed = false;
    final file = await _recordFile(key);
    if (await file.exists()) {
      await file.delete();
      changed = true;
    }
    final legacy = _legacyFile(key);
    if (legacy != null && await legacy.exists()) {
      await legacy.delete();
      changed = true;
    }
    if (changed) notifyListeners(key);
  }

  @override
  Future<bool> exists(String key) async {
    if (await (await _recordFile(key)).exists()) return true;
    final legacy = _legacyFile(key);
    return legacy != null && await legacy.exists();
  }

  @override
  Future<void> clear() async {
    final directory = await _storageDirectory;
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.boxx')) {
        await entity.delete();
      }
    }
    notifyListeners('*');
  }

  @override
  Future<List<String>> getKeys() async {
    final keys = <String>{};
    final directory = await _storageDirectory;
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.boxx')) {
        final decoded = codec.decode(
          await entity.readAsString(),
          allowLegacy: false,
        );
        keys.add(decoded.key);
      }
    }
    return keys.toList()..sort();
  }

  @override
  Future<List<dynamic>> getValues() async {
    final keys = await getKeys();
    return Future.wait(keys.map(get));
  }

  Future<void> _writeAtomically(File destination, String contents) async {
    final temporary = File(
      '${destination.path}.tmp-${Random.secure().nextInt(1 << 32)}',
    );
    try {
      await temporary.writeAsString(contents, flush: true);
      await temporary.rename(destination.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }
}
