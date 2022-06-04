import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

///
///
///
void main(List<String> arguments) {
  String rootPath = '';

  if (arguments.contains('--path')) {
    int pos = arguments.indexOf('--path');

    if (pos + 2 > arguments.length) {
      exitError('--path value not found');
    } else {
      rootPath = arguments[pos + 1];
    }
  } else {
    exitError('--path is required.');
  }

  if (rootPath.isEmpty || !Directory(rootPath).existsSync()) {
    exitError('--path value not exists.');
  }

  ///
  /// config.yml
  ///
  String configPath = p.normalize(p.join(rootPath, 'config.yml'));

  File configYml = File(configPath);

  if (!configYml.existsSync()) {
    exitError('config.yml not found in $rootPath.');
  }

  yaml.YamlMap doc = yaml.loadYaml(configYml.readAsStringSync());

  ///
  /// savePath
  ///
  String savePath = '';
  if (!doc.containsKey('savePath')) {
    exitError('config.yml not contains savePath.');
  } else {
    try {
      savePath = doc['savePath'];
    } on Exception catch (_) {
      exitError('savePath has a invalid value on config.yml');
    }
  }

  savePath = p.join(rootPath, savePath);

  Directory saveDir = Directory(savePath);

  if (!saveDir.existsSync()) {
    exitError('$savePath not found.');
  }

  ///
  /// checkPath
  ///
  String checkPath = '';
  if (!doc.containsKey('checkPath')) {
    exitError('config.yml not contains checkPath.');
  } else {
    try {
      checkPath = doc['checkPath'];
    } on Exception catch (_) {
      exitError('checkPath has a invalid value on config.yml');
    }
  }

  checkPath = p.normalize(p.join(rootPath, checkPath));

  Directory checkDir = Directory(checkPath);

  if (!checkDir.existsSync()) {
    exitError('$checkDir not found.');
  }

  ///
  /// regexCheckFiles
  ///
  List<RegExp> regexCheckFiles = <RegExp>[];
  if (!doc.containsKey('regexCheckFiles')) {
    exitError('config.yml not contains regexCheckFiles list.');
  } else {
    try {
      regexCheckFiles = (doc['regexCheckFiles'] as yaml.YamlList)
          .map((dynamic e) => RegExp(e.toString()))
          .toList();
    } on Exception catch (_) {
      exitError('checkPath has a invalid value on config.yml');
    }
  }

  /// Paths to check
  List<FileSystemEntity> dirs = saveDir.listSync(followLinks: false)
    ..retainWhere((FileSystemEntity e) => e is Directory);

  List<String> dirNames = dirs
      .map((FileSystemEntity e) => e.path.split(p.separator).last)
      .toList()
    ..sort((String a, String b) => a.compareTo(b));

  /// Search in path
  for (String dirName in dirNames) {
    print('Checking: $dirName');

    String checkNamePath = p.normalize(p.join(checkPath, dirName));

    Directory checkNameDir = Directory(checkNamePath);

    if (checkNameDir.existsSync()) {
      /// List files
      List<FileSystemEntity> entities = checkNameDir.listSync(
        recursive: true,
        followLinks: false,
      )..retainWhere((FileSystemEntity e) {
          if (e is File) {
            String filename = e.path.split(p.separator).last;
            for (RegExp regexp in regexCheckFiles) {
              if (regexp.hasMatch(filename)) {
                print('Found: ${e.path}');
                return true;
              }
            }
          }
          return false;
        });

      /// Copy files
      for (FileSystemEntity entity in entities) {
        File origin = entity as File;

        File dest =
            File(p.join(savePath, p.relative(origin.path, from: checkPath)));

        if (dest.existsSync()) {
          dest.deleteSync();
        } else {
          dest.parent.createSync(recursive: true);
        }

        origin.copySync(dest.path);

        String originPath = origin.path;

        origin.deleteSync();

        Link(originPath).createSync(dest.path);
      }
    } else {
      print('$checkNamePath not exists: ignoring.');
    }
  }
}

///
///
///
void exitError(String error, {int code = 1}) {
  print(error);
  exit(code);
}
