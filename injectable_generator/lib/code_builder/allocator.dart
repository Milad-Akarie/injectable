import 'package:code_builder/code_builder.dart';

/// The reason to use this allocator is to avoid changing in the alias of the imports
/// With this allocator, we can hash the url of the import and use it as an alias
/// This will make sure that the alias is consistent across multiple runs avoiding conflicts
class HashedAllocator implements Allocator {
  static const _doNotPrefix = ['dart:core'];

  final _imports = <String, int>{};

  String? _url;

  @override
  String allocate(Reference reference) {
    final symbol = reference.symbol;
    _url = reference.url;
    if (_url == null || _doNotPrefix.contains(_url)) {
      return symbol!;
    }

    return '_i${_imports.putIfAbsent(_url!, _hashedUrl)}.$symbol';
  }

  int _hashedUrl() => _url.hashCode / 1000000 ~/ 1;

  @override
  Iterable<Directive> get imports =>
      _imports.keys.map((u) => Directive.import(u, as: '_i${_imports[u]}'));
}
