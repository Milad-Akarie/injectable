import 'dart:convert';

class PubspecLocalPackageDependenciesResolver {
  final List<String> _pubspecYamlLines;

  PubspecLocalPackageDependenciesResolver(String yamlFileContent)
      : _pubspecYamlLines = LineSplitter().convert(yamlFileContent).toList();

  List<String> get resolvedDependencies {
    final copiedLines = _pubspecYamlLines.toList();
    for (final line in _pubspecYamlLines) {
      if (line == 'dependencies:') {
        break;
      }
      copiedLines.remove(line);
    }

    int? endOfDependenciesIndex;
    for (final line in copiedLines.skip(1) /*skip 'dependencies:' key*/) {
      if (line.startsWith('  ') == false) {
        endOfDependenciesIndex = copiedLines.indexOf(line);
        break;
      }
    }

    endOfDependenciesIndex ??= copiedLines.length;

    // Sublist in range [0, endOfDependenciesIndex) will only contain entries within 'dependencies:' key.
    // If the for-loop above matches a new dictionary key (a line without leading whitespace),
    // the sublist will contain the elements 'dependencies:' and all the following lines
    // until, but not including, the next dictionary key (e.g. 'dev_dependencies:').
    // Otherwise, if no new dictionary key is matched, the sublist operation will be idempotent.
    final dependenciesList = copiedLines.sublist(0, endOfDependenciesIndex);

    // Collect all dependencies with a local path (=> local dependencies)
    final localDependencies = dependenciesList.indexed.where((indexed) {
      if (indexed.$1 >= dependenciesList.length - 1) {
        return false;
      }

      return dependenciesList[indexed.$1 + 1].trim().startsWith('path');
    }).map((element) => element.$2.trim().replaceAll(':', ''));

    return localDependencies.toList();
  }
}
