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
  /// regexAlwaysIgnorePaths
  ///
  List<RegExp> regexAlwaysIgnorePaths = <RegExp>[];
  if (doc.containsKey('regexAlwaysIgnore')) {
    try {
      regexAlwaysIgnorePaths = (doc['regexAlwaysIgnore'] as yaml.YamlList)
          .map((dynamic e) => RegExp(e.toString()))
          .toList();
    } on Exception catch (ex) {
      print(ex);
      exitError('regexAlwaysIgnore has a invalid value on config.yml');
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
    } on Exception catch (ex) {
      print(ex);
      exitError('regexCheckFiles has a invalid value on config.yml');
    }
  }

  /// Paths to check
  List<FileSystemEntity> dirs = saveDir.listSync(followLinks: false)
    ..retainWhere((FileSystemEntity e) => e is Directory);

  List<String> dirNames = dirs
      .map((FileSystemEntity e) => e.path.split(p.separator).last)
      .toList()
    ..sort((String a, String b) => a.compareTo(b));

  // print('RootPath: $rootPath');
  // print('SaveDir: $saveDir');
  // print('CheckDir: $checkDir');

  print('');
  print('');

  ///
  ///
  /// Search in path to save
  List<FileSystemEntity> allFiles = saveDir.listSync(
    recursive: true,
    followLinks: false,
  )..retainWhere((FileSystemEntity f) => f is File);

  for (FileSystemEntity dest in allFiles) {
    String originPath =
        p.join(checkPath, p.relative(dest.path, from: savePath));

    String originParent = p.dirname(originPath);

    Directory destDir = Directory(p.dirname(originPath));

    if (destDir.existsSync()) {
      List<FileSystemEntity> list = destDir.listSync(followLinks: false)
        ..retainWhere(
          (FileSystemEntity f) => f is! Directory && f.path == originPath,
        );

      String linkTarget = p.relative(dest.path, from: originParent);

      bool createLink = false;

      if (list.isEmpty) {
        createLink = true;
      } else {
        if (list.length == 1) {
          FileSystemEntity e = list.first;
          if (e is Link) {
            if (e.targetSync() != linkTarget) {
              print('Link updated to: $linkTarget\n$originPath');
              e.updateSync(linkTarget);
            }
          } else if (e is File) {
            print('Expected a link but found a file.');
            String backup = '${e.path}.bkp';
            print('Backup created: $backup');
            e.renameSync(backup);
            createLink = true;
          } else {
            print('Unknown FileSystemEntity type: $e\n$originPath');
          }
        } else {
          print('Found more than one file. Ignoring.\n$originPath');
        }
      }

      if (createLink) {
        Link(originPath).createSync(linkTarget);
        print('Link created: $originPath');
      }
    } else {
      print('Skipping: project not exists. $originPath');
    }
  }

  print('');
  print('');

  ///
  ///
  ///
  /// Search in path to check
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
            for (RegExp regExp in regexAlwaysIgnorePaths) {
              if (regExp.hasMatch(e.path)) {
                return false;
              }
            }

            String filename = p.basename(e.path);
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
          String backup = '${dest.path}.bkp';
          print('Backup created: $backup');
          dest.renameSync(backup);
        } else {
          dest.parent.createSync(recursive: true);
        }

        origin.copySync(dest.path);

        String originPath = origin.path;

        String originParent = origin.parent.path;

        origin.deleteSync();

        Link(originPath).createSync(p.relative(dest.path, from: originParent));
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
