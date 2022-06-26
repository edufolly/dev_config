import 'dart:io';
import 'package:yaml/yaml.dart' as yaml;

///
///
///
void main(List<String> arguments) {
  print('Build Meta');

  File pubspec = File('pubspec.yaml');

  if (!pubspec.existsSync()) {
    exitError('pubspec.yaml not found');
  }

  yaml.YamlMap doc = yaml.loadYaml(pubspec.readAsStringSync());

  if (!doc.containsKey('version')) {
    exitError('version not found in pubspec.yaml');
  }

  String version = doc['version'];

  print(version);

  File meta = File('bin/meta.dart');

  if (!meta.existsSync()) {
    exitError('bin/meta.dart not found');
  }

  String content = meta.readAsStringSync();

  content = content.replaceAll("version = 'dev';", "version = '$version';");

  meta.writeAsString(content, flush: true);
}

///
///
///
void exitError(String error, {int code = 1}) {
  print(error);
  exit(code);
}
