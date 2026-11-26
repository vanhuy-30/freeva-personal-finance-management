import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/auth_repository.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/avatar_image.dart';
import '../../domain/avatar_picker.dart';
import '../../domain/avatar_repository.dart';

Future<Uint8List?> _prepareOffThread(Uint8List source) =>
    compute(prepareAvatar, source);

enum AvatarOutcome { saved, removed, cancelled, unreadable, failed }

/// The profile photo shown on Cá nhân and Hồ sơ. Loaded once the app is
/// unlocked, dropped when the person signs out.
@lazySingleton
class AvatarViewModel extends ChangeNotifier {
  AvatarViewModel(
    this._repository,
    this._picker,
    this._auth, {
    @ignoreParam Future<Uint8List?> Function(Uint8List)? prepare,
  }) : _prepare = prepare ?? _prepareOffThread {
    _stage = _auth.stage;
    _auth.addListener(_authChanged);
    if (_stage == AuthStage.unlocked) unawaited(load());
  }

  final AvatarRepository _repository;
  final AvatarPicker _picker;
  final AuthViewModel _auth;
  final Future<Uint8List?> Function(Uint8List) _prepare;
  late AuthStage _stage;
  int _epoch = 0;

  /// The JPEG, or null for the letter avatar.
  Uint8List? image;

  /// A photo is being saved or removed.
  bool busy = false;

  void _authChanged() {
    if (_stage == _auth.stage) return;
    _stage = _auth.stage;
    _epoch++;
    image = null;
    busy = false;
    notifyListeners();
    if (_stage == AuthStage.unlocked) unawaited(load());
  }

  /// Fetches the photo; a failure keeps what is shown (the letter, at worst).
  Future<void> load() async {
    if (_stage != AuthStage.unlocked) return;
    final epoch = ++_epoch;
    final result = await _repository.load();
    if (epoch != _epoch) return;
    result.fold(_failed, (photo) {
      image = photo;
      notifyListeners();
    });
  }

  /// Takes or picks a photo, resizes it and saves it.
  Future<AvatarOutcome> change(AvatarSource source) async {
    if (busy || _stage != AuthStage.unlocked) return AvatarOutcome.cancelled;
    final picked = await _picker.pick(source);
    if (picked == null) return AvatarOutcome.cancelled;
    final epoch = ++_epoch;
    busy = true;
    notifyListeners();
    final jpeg = await _prepare(picked);
    if (epoch != _epoch) return AvatarOutcome.cancelled;
    if (jpeg == null) {
      busy = false;
      notifyListeners();
      return AvatarOutcome.unreadable;
    }
    final result = await _repository.save(jpeg);
    if (epoch != _epoch) return AvatarOutcome.cancelled;
    busy = false;
    return result.fold(
      (error) {
        _failed(error);
        notifyListeners();
        return AvatarOutcome.failed;
      },
      (_) {
        image = jpeg;
        notifyListeners();
        return AvatarOutcome.saved;
      },
    );
  }

  Future<AvatarOutcome> remove() async {
    if (busy || _stage != AuthStage.unlocked || image == null) {
      return AvatarOutcome.cancelled;
    }
    final epoch = ++_epoch;
    busy = true;
    notifyListeners();
    final result = await _repository.remove();
    if (epoch != _epoch) return AvatarOutcome.cancelled;
    busy = false;
    return result.fold(
      (error) {
        _failed(error);
        notifyListeners();
        return AvatarOutcome.failed;
      },
      (_) {
        image = null;
        notifyListeners();
        return AvatarOutcome.removed;
      },
    );
  }

  void _failed(AuthFailure error) {
    if (error.code == AuthError.expired) _auth.sessionExpired();
  }

  @override
  void dispose() {
    _epoch++;
    _auth.removeListener(_authChanged);
    super.dispose();
  }
}
