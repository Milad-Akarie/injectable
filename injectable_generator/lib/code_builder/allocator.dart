import 'package:code_builder/code_builder.dart';

/// The reason to use this allocator is to avoid changing in the alias of the imports
/// With this allocator, we can hash the url of the import and use it as an alias
/// This will make sure that the alias is consistent across multiple runs avoiding conflicts
class HashedAllocator implements Allocator {
  static const _doNotPrefix = ['dart:core'];

  /// Tracks used import URLs and their assigned aliases.
  final _imports = <String, int>{};

  /// Tracks used alias integers to avoid collisions.
  final _usedAliases = <int>{};

  String? _url;

  /// Allocates a unique alias for the [reference]'s URL.
  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol;
    _url = reference.url;
    if (_url == null || _doNotPrefix.contains(_url)) {
      return symbol!;
    }

    return '_i${_imports.putIfAbsent(_url!, _hashedUrl)}.$symbol';
  }

  int _hashedUrl() {
    var alias = _url.hashCode / 1000000 ~/ 1;
    while (!_usedAliases.add(alias)) {
      alias++;
    }

    return alias;
  }

  @override
  Iterable<Directive> get imports =>
      _imports.keys.map((u) => Directive.import(u, as: '_i${_imports[u]}'));
}
