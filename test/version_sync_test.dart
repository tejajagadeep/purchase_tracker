import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchase_tracker/constants/app_constants.dart';

void main() {
  test('Verify AppConstants.appVersion matches pubspec.yaml version', () {
    final pubspecFile = File('pubspec.yaml');
    expect(pubspecFile.existsSync(), true, reason: 'pubspec.yaml must exist');

    final pubspecContent = pubspecFile.readAsStringSync();

    // Parse version string from pubspec.yaml (e.g. version: 2.1.3+1)
    final versionMatch = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(\+[0-9]+)?',
      multiLine: true,
    ).firstMatch(pubspecContent);

    expect(
      versionMatch,
      isNotNull,
      reason:
          'pubspec.yaml must contain a valid version string (e.g. version: 2.1.3+1)',
    );

    final pubspecVersion = versionMatch!.group(1);
    final constantVersion = AppConstants.appVersion;

    expect(
      constantVersion,
      equals(pubspecVersion),
      reason:
          'BUILD FAILED: AppConstants.appVersion ("$constantVersion") does not match pubspec.yaml version ("$pubspecVersion")! '
          'Please update AppConstants.appVersion in lib/constants/app_constants.dart to "$pubspecVersion".',
    );
  });
}
