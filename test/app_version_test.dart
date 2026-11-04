import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymflow/core/app_version.dart';

void main() {
  test('appVersion é a versão do pubspec.yaml', () {
    final line = File(
      'pubspec.yaml',
    ).readAsLinesSync().firstWhere((l) => l.startsWith('version:'));
    final pubspecVersion = line.split(':')[1].trim().split('+').first;
    expect(appVersion, pubspecVersion);
  });
}
