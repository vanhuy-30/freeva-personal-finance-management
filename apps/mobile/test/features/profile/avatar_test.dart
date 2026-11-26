import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/profile/data/avatar_repository_impl.dart';
import 'package:mobile/features/profile/domain/avatar_image.dart';
import 'package:mobile/features/profile/domain/avatar_picker.dart';
import 'package:mobile/features/profile/presentation/viewmodels/avatar_view_model.dart';

import '../../support/server_config_fixture.dart';
import '../auth/fakes.dart';
import 'avatar_fakes.dart';
import 'fakes.dart';

DefaultAuthViewModel _auth() =>
    DefaultAuthViewModel(
        DefaultAuthUseCases(
          AuthRepositoryImpl(
            FakeApi(),
            MemoryVault(),
            FakeBiometrics(),
            testServerConfigModel(),
          ),
          testServerConfigModel(),
        ),
      )
      ..stage = AuthStage.unlocked
      ..hasPin = true
      ..ready = true;

void main() {
  group('prepareAvatar', () {
    test(
      'crops the centre square, scales it down and returns a small JPEG',
      () {
        final jpeg = prepareAvatar(samplePicture(width: 1000, height: 600))!;
        expect(jpeg.take(3), [0xff, 0xd8, 0xff]);
        expect(jpeg.length, lessThanOrEqualTo(avatarMaxBytes));
        final decoded = img.decodeJpg(jpeg)!;
        expect((decoded.width, decoded.height), (avatarSide, avatarSide));
      },
    );

    test('keeps a small picture at its own size', () {
      final decoded = img.decodeJpg(
        prepareAvatar(samplePicture(width: 100, height: 100))!,
      )!;
      expect((decoded.width, decoded.height), (100, 100));
    });

    test('is null for bytes that are not a picture', () {
      expect(prepareAvatar(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });
  });

  group('AvatarViewModel', () {
    late DefaultAuthViewModel auth;
    late FakeAvatarRepository repository;
    late FakeAvatarPicker picker;
    late AvatarViewModel model;

    setUp(() {
      auth = _auth();
      repository = FakeAvatarRepository();
      picker = FakeAvatarPicker();
      model = avatarViewModel(auth, repository: repository, picker: picker);
    });
    tearDown(() {
      model.dispose();
      auth.dispose();
    });

    test('loads the photo of the account when unlocked', () async {
      final fresh = FakeAvatarRepository()..stored = Uint8List.fromList([9]);
      final other = avatarViewModel(auth, repository: fresh);
      await Future<void>.delayed(Duration.zero);
      expect(other.image, [9]);
      other.dispose();
    });

    test('change: picks, resizes, saves and shows the new photo', () async {
      picker.next = samplePicture();
      expect(await model.change(AvatarSource.camera), AvatarOutcome.saved);
      expect(picker.lastSource, AvatarSource.camera);
      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.take(3), [0xff, 0xd8, 0xff]);
      expect(model.image, repository.saved.single);
      expect(model.busy, isFalse);
    });

    test('change: backing out of the picker changes nothing', () async {
      expect(await model.change(AvatarSource.library), AvatarOutcome.cancelled);
      expect(repository.saved, isEmpty);
      expect(model.image, isNull);
    });

    test(
      'change: a file that is not a picture is reported, not sent',
      () async {
        picker.next = Uint8List.fromList([1, 2, 3]);
        expect(
          await model.change(AvatarSource.library),
          AvatarOutcome.unreadable,
        );
        expect(repository.saved, isEmpty);
        expect(model.busy, isFalse);
      },
    );

    test(
      'change: a failed save keeps the old photo; expiry signs out',
      () async {
        model.image = Uint8List.fromList([7]);
        picker.next = samplePicture();
        repository.failure = const AuthFailure(AuthError.network);
        expect(await model.change(AvatarSource.library), AvatarOutcome.failed);
        expect(model.image, [7]);
        repository.failure = const AuthFailure(AuthError.expired);
        expect(await model.change(AvatarSource.library), AvatarOutcome.failed);
        expect(auth.stage, AuthStage.signedOut);
      },
    );

    test('remove: back to the letter; nothing to remove is a no-op', () async {
      expect(await model.remove(), AvatarOutcome.cancelled);
      model.image = Uint8List.fromList([7]);
      expect(await model.remove(), AvatarOutcome.removed);
      expect(model.image, isNull);
    });

    test('remove: a failure keeps the photo', () async {
      model.image = Uint8List.fromList([7]);
      repository.failure = const AuthFailure(AuthError.network);
      expect(await model.remove(), AvatarOutcome.failed);
      expect(model.image, [7]);
    });

    test('signing out drops the photo', () async {
      model.image = Uint8List.fromList([7]);
      auth.stage = AuthStage.signedOut;
      auth.notifyListeners();
      expect(model.image, isNull);
    });
  });

  group('AvatarRepositoryImpl', () {
    late Transport api;
    late AvatarRepositoryImpl repository;
    setUp(() {
      api = Transport();
      repository = AvatarRepositoryImpl(api);
    });

    test('save sends the photo as base64 with PUT profile/avatar', () async {
      final result = await repository.save(Uint8List.fromList([1, 2, 3]));
      expect(result, right(unit));
      expect((api.method, api.path), ('PUT', 'profile/avatar'));
      expect(api.body, {
        'imageBase64': base64Encode([1, 2, 3]),
      });
    });

    test('remove is DELETE profile/avatar', () async {
      await repository.remove();
      expect((api.method, api.path), ('DELETE', 'profile/avatar'));
    });

    test(
      'load: no photo on the profile means null without a second call',
      () async {
        api.response = {'avatarUpdatedAt': null};
        final result = await repository.load();
        expect(result, right<AuthFailure, Uint8List?>(null));
        expect(api.path, 'profile');
      },
    );

    test(
      'load: fetches and decodes the photo when the profile has one',
      () async {
        api.response = {
          'avatarUpdatedAt': '2026-11-24T00:00:00.000Z',
          'imageBase64': base64Encode([5, 6, 7]),
        };
        final result = await repository.load();
        expect(result.getOrElse(() => null), [5, 6, 7]);
        expect(api.path, 'profile/avatar');
      },
    );

    test('load: a failure comes back as a failure', () async {
      api.failure = const AuthFailure(AuthError.network);
      expect((await repository.load()).isLeft(), isTrue);
    });
  });
}
