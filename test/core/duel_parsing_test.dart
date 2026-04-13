import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/duel_model.dart';
import 'package:kitaplig/core/services/duel_service.dart';

void main() {
  group('DuelModel.fromJson', () {
    test('int alanlari dogrudan parse eder', () {
      final duel = DuelModel.fromJson(_duelJson());

      expect(duel.id, 2);
      expect(duel.challengerId, 3);
      expect(duel.opponentId, 8);
      expect(duel.challengerScore, 0);
      expect(duel.opponentScore, 0);
      expect(duel.pointsAtStake, 50);
      expect(duel.winnerId, isNull);
      expect(duel.challenger?.id, 3);
      expect(duel.opponent?.id, 8);
    });

    test('num ve double alanlari int olarak parse eder', () {
      final duel = DuelModel.fromJson(
        _duelJson().map((key, value) {
          switch (key) {
            case 'id':
              return MapEntry(key, 2.0);
            case 'challenger_id':
              return MapEntry(key, 3.0);
            case 'opponent_id':
              return MapEntry(key, 8.0);
            case 'challenger_score':
              return MapEntry(key, 0.0);
            case 'opponent_score':
              return MapEntry(key, 0.0);
            case 'points_at_stake':
              return MapEntry(key, 50.0);
            default:
              return MapEntry(key, value);
          }
        }),
      );

      expect(duel.id, 2);
      expect(duel.challengerId, 3);
      expect(duel.opponentId, 8);
      expect(duel.pointsAtStake, 50);
    });

    test('numeric string alanlari parse eder', () {
      final duel = DuelModel.fromJson({
        ..._duelJson(),
        'id': '2',
        'challenger_id': '3',
        'opponent_id': '8',
        'challenger_score': '0',
        'opponent_score': '0',
        'points_at_stake': '50',
        'challenger': {'id': '3', 'name': 'ali can', 'avatar_url': null},
        'opponent': {'id': '8', 'name': 'elif duru yalçın', 'avatar_url': null},
      });

      expect(duel.id, 2);
      expect(duel.challenger?.id, 3);
      expect(duel.opponent?.id, 8);
    });

    test('winner_id null ise guvenli calisir', () {
      final duel = DuelModel.fromJson({..._duelJson(), 'winner_id': null});

      expect(duel.winnerId, isNull);
    });

    test('gecersiz zorunlu sayisal alanlarda FormatException firlatir', () {
      expect(
        () => DuelModel.fromJson({..._duelJson(), 'id': 'iki'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('profil scope varken ayni hesaptaki rolleri user id ile karistirmaz', () {
      final duel = DuelModel.fromJson({
        ..._duelJson(),
        'challenger_id': 5,
        'challenger_reader_profile_id': 11,
        'opponent_id': 5,
        'opponent_reader_profile_id': 12,
        'challenger': {
          'id': 5,
          'reader_profile_id': 11,
          'name': 'Ada Çocuk',
          'avatar_url': null,
        },
        'opponent': {
          'id': 5,
          'reader_profile_id': 12,
          'name': 'Efe Çocuk',
          'avatar_url': null,
        },
      });

      expect(
        duel.isIncomingForActor(userId: 5, readerProfileId: 11),
        isFalse,
      );
      expect(duel.isOutgoingForActor(userId: 5, readerProfileId: 11), isTrue);
      expect(duel.isIncomingForActor(userId: 5, readerProfileId: 12), isTrue);
      expect(
        duel.isOutgoingForActor(userId: 5, readerProfileId: 12),
        isFalse,
      );
      expect(
        duel.otherUserForActor(userId: 5, readerProfileId: 12)?.readerProfileId,
        11,
      );
    });
  });

  group('DuelService hata parse akisi', () {
    test('409 payloadinda action result doner ve exception yutulur', () {
      final payload = {
        'success': false,
        'message': 'Bu kullanıcıyla zaten açık bir düellon var.',
        'data': {
          ..._duelJson(),
          'id': 2.0,
          'challenger_id': 3.0,
          'opponent_id': 8.0,
          'points_at_stake': 50.0,
          'challenger': {'id': 3.0, 'name': 'ali can', 'avatar_url': null},
          'opponent': {
            'id': 8.0,
            'name': 'elif duru yalçın',
            'avatar_url': null,
          },
        },
      };

      final exception = DioException(
        requestOptions: RequestOptions(path: '/duels/challenge/8'),
        response: Response(
          requestOptions: RequestOptions(path: '/duels/challenge/8'),
          statusCode: 409,
          data: payload,
        ),
        type: DioExceptionType.badResponse,
      );

      final result = DuelService.actionResultFromError(
        exception,
        fallback: 'Düello teklifi gönderilemedi.',
      );

      expect(result.success, isFalse);
      expect(result.message, 'Bu kullanıcıyla zaten açık bir düellon var.');
      expect(result.duel, isNotNull);
      expect(result.duel?.id, 2);
      expect(result.duel?.opponent?.name, 'elif duru yalçın');
    });

    test('parse edilemeyen data olsa bile null duel ile stabil kalir', () {
      final exception = DioException(
        requestOptions: RequestOptions(path: '/duels/challenge/8'),
        response: Response(
          requestOptions: RequestOptions(path: '/duels/challenge/8'),
          statusCode: 409,
          data: {
            'success': false,
            'message': 'Bu kullanıcıyla zaten açık bir düellon var.',
            'data': {'id': 'bozuk'},
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final result = DuelService.actionResultFromError(
        exception,
        fallback: 'Düello teklifi gönderilemedi.',
      );

      expect(result.success, isFalse);
      expect(result.message, 'Bu kullanıcıyla zaten açık bir düellon var.');
      expect(result.duel, isNull);
    });
  });
}

Map<String, dynamic> _duelJson() {
  return {
    'id': 2,
    'challenger_id': 3,
    'opponent_id': 8,
    'status': 'pending',
    'challenger_score': 0,
    'opponent_score': 0,
    'points_at_stake': 50,
    'winner_id': null,
    'starts_at': null,
    'expires_at': null,
    'challenger': {'id': 3, 'name': 'ali can', 'avatar_url': null},
    'opponent': {'id': 8, 'name': 'elif duru yalçın', 'avatar_url': null},
  };
}
