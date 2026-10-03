import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/media_vault.dart';

/// Shows a photo from the encrypted [MediaVault]. Decrypted bytes stay in a
/// small in-memory cache only, never on disk.
class VaultImage extends StatefulWidget {
  const VaultImage(
    this.storedPath, {
    super.key,
    this.fit = BoxFit.cover,
    this.vault,
  });

  final String storedPath;
  final BoxFit fit;
  final MediaVault? vault;

  static final _cache = <String, Uint8List>{};
  static const _cacheSize = 24;

  /// Drops cached photos, for example after Delete All or a restore.
  static void clearCache() => _cache.clear();

  @override
  State<VaultImage> createState() => _VaultImageState();
}

class _VaultImageState extends State<VaultImage> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant VaultImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storedPath != widget.storedPath) {
      _bytes = null;
      _failed = false;
      _load();
    }
  }

  Future<void> _load() async {
    final cached = VaultImage._cache.remove(widget.storedPath);
    if (cached != null) {
      VaultImage._cache[widget.storedPath] = cached;
      setState(() => _bytes = cached);
      return;
    }
    try {
      final bytes = await (widget.vault ?? MediaVault()).read(widget.storedPath);
      VaultImage._cache[widget.storedPath] = bytes;
      while (VaultImage._cache.length > VaultImage._cacheSize) {
        VaultImage._cache.remove(VaultImage._cache.keys.first);
      }
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_failed) {
      return ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined, color: scheme.outline),
      );
    }
    final bytes = _bytes;
    if (bytes == null) {
      return ColoredBox(color: scheme.surfaceContainerHighest);
    }
    return Image.memory(
      bytes,
      fit: widget.fit,
      gaplessPlayback: true,
      // Large photos are decoded at the size they are shown.
      cacheWidth: widget.fit == BoxFit.cover ? 480 : null,
    );
  }
}

/// Full-screen, swipeable, zoomable view of an entry's photos.
class VaultGalleryScreen extends StatefulWidget {
  const VaultGalleryScreen({
    super.key,
    required this.paths,
    this.initialIndex = 0,
  });

  final List<String> paths;
  final int initialIndex;

  static Future<void> open(
    BuildContext context,
    List<String> paths,
    int index,
  ) {
    return Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => VaultGalleryScreen(paths: paths, initialIndex: index),
    ));
  }

  @override
  State<VaultGalleryScreen> createState() => _VaultGalleryScreenState();
}

class _VaultGalleryScreenState extends State<VaultGalleryScreen> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.paths.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.paths.length,
        onPageChanged: (value) => setState(() => _index = value),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 5,
          child: Center(
            child: VaultImage(widget.paths[i], fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
