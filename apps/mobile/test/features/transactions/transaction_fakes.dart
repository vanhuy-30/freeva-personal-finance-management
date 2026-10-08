import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';

class ScriptedApi implements AuthorizedApi {
  final calls =
      <
        ({
          String method,
          String path,
          Map<String, dynamic>? body,
          Map<String, String>? headers,
        })
      >[];
  AuthFailure? failure;
  int? failWrite;
  int writes = 0;
  bool conflict = false;
  bool paginate = false;
  Completer<void>? pending;

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: method, path: path, body: body, headers: headers));
    if (pending != null) await pending!.future;
    if (failure != null) return left(failure!);
    if (path.startsWith('financial-accounts')) {
      return right({
        'items': [_wallet('cash', 0), _wallet('card', 1, type: 'credit')],
        'total': 2,
      });
    }
    if (path == 'profile/options') {
      return right({
        'currencies': [
          {'code': 'VND', 'minorDigits': 0},
          {'code': 'USD', 'minorDigits': 2},
        ],
      });
    }
    if (path == 'categories/defaults') return right({});
    if (path == 'categories/recent') {
      return right({
        'items': [_category('food', 'Ăn uống')],
      });
    }
    if (path.startsWith('categories?')) {
      return right({
        'items': [_category('food', 'Ăn uống')],
        'total': 1,
      });
    }
    if (method == 'GET' && path.startsWith('transactions?')) {
      final page = int.parse(
        Uri.parse('http://local/$path').queryParameters['page']!,
      );
      final first = _leg('old', accountId: 'card');
      final second = _leg('older', accountId: 'cash');
      return right({
        'items': paginate ? [page == 1 ? first : second] : [first],
        'page': page,
        'pageSize': 50,
        'total': paginate ? 2 : 1,
      });
    }
    if (method == 'GET' && path.startsWith('transactions/')) {
      return right({
        'legs': [_leg('old', accountId: 'card')],
        'fx': null,
      });
    }
    writes++;
    if (writes == failWrite) return left(const AuthFailure(AuthError.network));
    if (conflict) return left(const AuthFailure(AuthError.conflict));
    if (method == 'DELETE') return right({});
    return right(_bundle(body!));
  }
}

Map<String, dynamic> _wallet(String id, int order, {String type = 'cash'}) => {
  'id': id,
  'createdAt': '2026-01-01T00:00:00.000Z',
  'name': id,
  'type': type,
  'currencyCode': 'VND',
  'initialBalanceMinor': '0',
  'balanceMinor': '1000',
  'creditLimitMinor': null,
  'statementCloseDay': null,
  'paymentDueDay': null,
  'sortOrder': order,
  'version': 1,
  'archivedAt': null,
};

Map<String, dynamic> _category(String id, String name) => {
  'id': id,
  'name': name,
  'parentId': null,
};

Map<String, dynamic> _leg(String id, {required String accountId}) => {
  'id': id,
  'clientId': '11111111-1111-4111-8111-111111111111',
  'accountId': accountId,
  'currencyCode': 'VND',
  'amountMinor': '-1000',
  'type': 'expense',
  'occurredOn': '2026-01-02',
  'categoryId': 'food',
  'notes': null,
  'tagIds': <String>[],
  'transferGroupId': null,
  'fxQuoteId': null,
  'deletedAt': null,
  'version': 1,
  'createdAt': '2026-01-02T00:00:00.000Z',
  'updatedAt': '2026-01-02T00:00:00.000Z',
};

Map<String, dynamic> _bundle(Map<String, dynamic> body) {
  final legs = (body['legs'] as List).cast<Map<String, dynamic>>();
  return {
    'legs': [
      for (var i = 0; i < legs.length; i++)
        {
          ..._leg('created-$i', accountId: legs[i]['accountId'] as String),
          ...legs[i],
          'type': body['type'],
          'occurredOn': body['occurredOn'],
          'categoryId': body['categoryId'],
          'notes': body['notes'],
          'transferGroupId': legs.length == 2 ? 'group-1' : null,
          'deletedAt': null,
          'version': (body['version'] as int? ?? 0) + 1,
        },
    ],
    'fx': body['fx'] == null
        ? null
        : {
            'id': 'fx-1',
            'fromCode': legs.first['currencyCode'],
            'toCode': legs.last['currencyCode'],
            'rate': (body['fx'] as Map)['rate'],
            'quotedAt': (body['fx'] as Map)['quotedAt'],
          },
  };
}
