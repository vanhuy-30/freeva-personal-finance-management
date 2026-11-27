import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_link.dart';

void main() {
  final token = 'ab12' * 16;

  String? tokenOf(String uri) {
    final link = AuthLinkParser.parse(Uri.parse(uri));
    return link is ResetPasswordLink ? link.token : null;
  }

  group('reset links', () {
    test('custom scheme with the token in the query', () {
      expect(tokenOf('freeva://reset-password?token=$token'), token);
    });

    test('https link with the token in the fragment or the query', () {
      expect(tokenOf('https://freeva.com/reset-password#token=$token'), token);
      expect(tokenOf('https://freeva.com/reset-password?token=$token'), token);
      expect(
        tokenOf('https://api.example.test/reset-password/#token=$token'),
        token,
      );
    });

    test('upper-case hex, whitespace and a shouting scheme are normalised', () {
      expect(
        tokenOf('FREEVA://Reset-Password?token=${token.toUpperCase()}'),
        token,
      );
      expect(tokenOf('freeva://reset-password?token=%20$token%20'), token);
    });

    test('the query wins when both query and fragment carry a token', () {
      expect(
        tokenOf('freeva://reset-password?token=$token#token=${'cd' * 32}'),
        token,
      );
    });

    test('extra parameters are ignored', () {
      expect(
        tokenOf('freeva://reset-password?utm=x&token=$token&other=1'),
        token,
      );
    });
  });

  group('invalid reset links', () {
    for (final uri in [
      'freeva://reset-password',
      'freeva://reset-password?token=',
      'freeva://reset-password?token=abc',
      'freeva://reset-password?token=${'g' * 64}',
      'freeva://reset-password?token=${token}00',
      'freeva://reset-password?token=${token.substring(1)}',
      'https://freeva.com/reset-password',
      'https://freeva.com/reset-password#',
      'https://freeva.com/reset-password#token',
      'https://freeva.com/reset-password#%',
    ]) {
      test('is flagged invalid: $uri', () {
        expect(AuthLinkParser.parse(Uri.parse(uri)), isA<InvalidAuthLink>());
      });
    }
  });

  group('links the app ignores', () {
    for (final uri in [
      'freeva://open',
      'freeva://verify-email?token=$token',
      'freeva://',
      'freeva:///',
      'freeva://reset-password/extra?token=$token',
      'https://freeva.com/',
      'https://freeva.com/other?token=$token',
      'https://freeva.com/reset-password/extra?token=$token',
      'https://freeva.com/a/reset-password?token=$token',
      'http://freeva.com/reset-password?token=$token',
      'otherapp://reset-password?token=$token',
      'mailto:someone@example.test',
    ]) {
      test('returns null: $uri', () {
        expect(AuthLinkParser.parse(Uri.parse(uri)), isNull);
      });
    }
  });

  test('path form of the custom scheme is accepted', () {
    expect(tokenOf('freeva:///reset-password?token=$token'), token);
  });
}
