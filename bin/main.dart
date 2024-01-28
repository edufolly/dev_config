import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart' as yaml;

import 'meta.dart';
import 'update.dart';

///
///
///
void main(List<String> arguments) async {
  print('dev-config [version ${Meta.version}]');
  print('');

  String rootPath = '';

  bool debug = false;

  if (arguments.contains('--debug')) {
    debug = true;
  }

  bool checkUpdate = true;

  if (arguments.contains('--no-check-update')) {
    checkUpdate = false;
  }

  if (checkUpdate) {
    await Update(debug: debug).check();
  }

  bool dryRun = false;

  if (arguments.contains('--dry-run')) {
    dryRun = true;
  }

  if (arguments.contains('--path')) {
    final int pos = arguments.indexOf('--path');

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
  final String configPath = p.normalize(p.join(rootPath, 'config.yml'));

  final File configYml = File(configPath);

  if (!configYml.existsSync()) {
    exitError('config.yml not found in $rootPath.');
  }

  final yaml.YamlMap doc = yaml.loadYaml(configYml.readAsStringSync());

  ///
  /// savePath
  ///
  String savePath = '';
  if (!doc.containsKey('savePath')) {
    exitError('config.yml not contains savePath.');
  } else {
    try {
      savePath = doc['savePath'];
    } on Exception catch (ex, st) {
      if (debug) {
        print(ex);
        print(st);
      }
      exitError('savePath has a invalid value on config.yml');
    }
  }

  savePath = p.join(rootPath, savePath);

  final Directory saveDir = Directory(savePath);

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
    } on Exception catch (ex, st) {
      if (debug) {
        print(ex);
        print(st);
      }
      exitError('checkPath has a invalid value on config.yml');
    }
  }

  checkPath = p.normalize(p.join(rootPath, checkPath));

  final Directory checkDir = Directory(checkPath);

  if (!checkDir.existsSync()) {
    exitError('$checkDir not found.');
  }

  ///
  /// regexAlwaysIgnorePaths
  ///
  List<RegExp> regexAlwaysIgnorePaths = <RegExp>[];
  if (doc.containsKey('regexAlwaysIgnorePaths')) {
    try {
      regexAlwaysIgnorePaths = (doc['regexAlwaysIgnorePaths'] as yaml.YamlList)
          .map((dynamic e) => RegExp(e.toString()))
          .toList();
    } on Exception catch (ex, st) {
      print(ex);
      if (debug) {
        print(st);
      }
      exitError('regexAlwaysIgnorePaths has a invalid value on config.yml');
    }
  }

  ///
  /// regexAlwaysAcceptPaths
  ///
  List<RegExp> regexAlwaysAcceptPaths = <RegExp>[];
  if (doc.containsKey('regexAlwaysAcceptPaths')) {
    try {
      regexAlwaysAcceptPaths = (doc['regexAlwaysAcceptPaths'] as yaml.YamlList)
          .map((dynamic e) => RegExp(e.toString()))
          .toList();
    } on Exception catch (ex, st) {
      print(ex);
      if (debug) {
        print(st);
      }
      exitError('regexAlwaysAcceptPaths has a invalid value on config.yml');
    }
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
    } on Exception catch (ex, st) {
      print(ex);
      if (debug) {
        print(st);
      }
      exitError('regexCheckFiles has a invalid value on config.yml');
    }
  }

  /// Paths to check
  final List<FileSystemEntity> dirs = saveDir.listSync(followLinks: false)
    ..retainWhere((FileSystemEntity e) => e is Directory);

  final List<String> dirNames = dirs
      .map((FileSystemEntity e) => e.path.split(p.separator).last)
      .toList()
    ..sort((String a, String b) => a.compareTo(b));

  // print('RootPath: $rootPath');
  // print('SaveDir: $saveDir');
  // print('CheckDir: $checkDir');

  ///
  ///
  /// Search in path to save
  final List<FileSystemEntity> allFiles = saveDir.listSync(
    recursive: true,
    followLinks: false,
  )..retainWhere((FileSystemEntity f) => f is File);

  for (final FileSystemEntity dest in allFiles) {
    final String originPath =
        p.join(checkPath, p.relative(dest.path, from: savePath));

    final String originParent = p.dirname(originPath);

    final Directory destDir = Directory(p.dirname(originPath));

    if (destDir.existsSync()) {
      final List<FileSystemEntity> list = destDir.listSync(followLinks: false)
        ..retainWhere(
          (FileSystemEntity f) => f is! Directory && f.path == originPath,
        );

      final String linkTarget = p.relative(dest.path, from: originParent);

      bool createLink = false;

      if (list.isEmpty) {
        createLink = true;
      } else {
        if (list.length == 1) {
          final FileSystemEntity e = list.first;
          if (e is Link) {
            if (e.targetSync() != linkTarget) {
              print('Link updated to: $linkTarget\n$originPath');
              if (!dryRun) {
                e.updateSync(linkTarget);
              }
            }
          } else if (e is File) {
            print('Expected a link but found a file. $e');
            final String backup = '${e.path}.bkp';
            print('Backup created: $backup');
            if (!dryRun) {
              e.renameSync(backup);
            }
            createLink = true;
          } else {
            print('Unknown FileSystemEntity type: $e\n$originPath');
          }
        } else {
          print('Found more than one file. Ignoring.\n$originPath');
        }
      }

      if (createLink) {
        if (!dryRun) {
          Link(originPath).createSync(linkTarget);
        }
        print('Link created: $originPath');
      }
    } else {
      print('Skipping: project not exists. $originPath');
    }
  }

  ///
  ///
  ///
  /// Search in path to check
  for (final String dirName in dirNames) {
    print('Checking: $dirName');

    final String checkNamePath = p.normalize(p.join(checkPath, dirName));

    final Directory checkNameDir = Directory(checkNamePath);

    if (checkNameDir.existsSync()) {
      /// List files
      List<FileSystemEntity> entities = <FileSystemEntity>[];

      try {
        entities = checkNameDir.listSync(
          recursive: true,
          followLinks: false,
        )..retainWhere((FileSystemEntity e) {
            if (e is File) {
              for (final RegExp regExp in regexAlwaysIgnorePaths) {
                if (regExp.hasMatch(e.path)) {
                  // if (debug) {
                  //   print('[regexAlwaysIgnorePaths] => ${e.path}');
                  // }
                  return false;
                }
              }

              for (final RegExp regExp in regexAlwaysAcceptPaths) {
                if (regExp.hasMatch(e.path)) {
                  if (debug) {
                    print('[regexAlwaysAcceptPaths] => ${e.path}');
                  }
                  return true;
                }
              }

              final String filename = p.basename(e.path);

              for (final RegExp regexp in regexCheckFiles) {
                if (regexp.hasMatch(filename)) {
                  if (debug) {
                    print('[regexCheckFiles] => ${e.path}');
                  }
                  return true;
                }
              }
            }
            return false;
          });
      } on PathAccessException catch (e) {
        print('[ERROR] PathAccessException: $checkNameDir');
        print(e.message);
        continue;
      }

      /// Copy files
      for (final FileSystemEntity entity in entities) {
        final File origin = entity as File;

        final File dest =
            File(p.join(savePath, p.relative(origin.path, from: checkPath)));

        final String destPath = dest.path;

        if (dest.existsSync()) {
          final String backup = '$destPath.bkp';
          print('Backup created: $backup');
          if (!dryRun) {
            dest.renameSync(backup);
          }
        } else {
          if (!dryRun) {
            dest.parent.createSync(recursive: true);
          }
        }

        final String originPath = origin.path;

        final String originParent = origin.parent.path;

        print('Copy: $originPath to $destPath');

        if (!dryRun) {
          origin
            ..copySync(destPath)
            ..deleteSync();

          Link(originPath).createSync(p.relative(destPath, from: originParent));
        }
      }
    } else {
      print('Skipping: project not exists. $checkNamePath');
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
