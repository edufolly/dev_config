import 'dart:math';

import 'package:http/http.dart';
import 'package:yaml/yaml.dart' as yaml;

import 'meta.dart';

///
///
///
class Update {
  final bool debug;

  ///
  ///
  ///
  const Update({this.debug = false});

  ///
  ///
  ///
  Future<void> check() async {
    try {
      Uri uri = Uri.parse(
        'https://raw.githubusercontent.com/edufolly/dev_config/main/pubspec.yaml',
      );

      String pubspec = await read(uri);

      yaml.YamlMap doc = yaml.loadYaml(pubspec);

      if (!doc.containsKey('version')) {
        return;
      }

      String version = doc['version'];

      num newVersion = parse(version);

      num thisVersion = parse(Meta.version);

      if (newVersion > thisVersion) {
        print('');
        print('New version is available: $version');
        print('Visit: https://github.com/edufolly/dev_config/releases/latest');
        print('');
      }
    } on Exception catch (e, s) {
      if (debug) {
        print(e);
        print(s);
      }
      return;
    }
  }

  ///
  ///
  ///
  num parse(String version) =>
      version.split('.').reversed.toList().asMap().entries.fold<num>(
            0,
            (num f, MapEntry<num, String> e) =>
                f + (pow(1000, e.key) * num.parse(e.value)),
          );
}
