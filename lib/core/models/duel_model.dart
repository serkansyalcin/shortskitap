class DuelModel {
  final int id;
  final int challengerId;
  final int opponentId;
  final String status;
  final int challengerScore;
  final int opponentScore;
  final int pointsAtStake;
  final int? winnerId;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DuelUserModel? challenger;
  final DuelUserModel? opponent;

  const DuelModel({
    required this.id,
    required this.challengerId,
    required this.opponentId,
    required this.status,
    required this.challengerScore,
    required this.opponentScore,
    required this.pointsAtStake,
    this.winnerId,
    this.startsAt,
    this.expiresAt,
    this.challenger,
    this.opponent,
  });

  factory DuelModel.fromJson(Map<String, dynamic> json) {
    return DuelModel(
      id: _DuelJsonParser.requiredInt(json, 'id'),
      challengerId: _DuelJsonParser.requiredInt(json, 'challenger_id'),
      opponentId: _DuelJsonParser.requiredInt(json, 'opponent_id'),
      status: json['status'] as String,
      challengerScore: _DuelJsonParser.requiredInt(json, 'challenger_score'),
      opponentScore: _DuelJsonParser.requiredInt(json, 'opponent_score'),
      pointsAtStake: _DuelJsonParser.requiredInt(json, 'points_at_stake'),
      winnerId: _DuelJsonParser.nullableInt(json, 'winner_id'),
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      challenger: json['challenger'] != null
          ? DuelUserModel.fromJson(json['challenger'] as Map<String, dynamic>)
          : null,
      opponent: json['opponent'] != null
          ? DuelUserModel.fromJson(json['opponent'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired';
  bool get isDeclined => status == 'declined';
  bool get isOpen => isPending || isActive;

  bool involvesUser(int userId) {
    return challengerId == userId || opponentId == userId;
  }

  bool isIncomingFor(int userId) {
    return isPending && opponentId == userId;
  }

  bool isOutgoingFor(int userId) {
    return isPending && challengerId == userId;
  }

  int? otherUserIdFor(int userId) {
    if (!involvesUser(userId)) {
      return null;
    }
    return challengerId == userId ? opponentId : challengerId;
  }

  DuelUserModel? otherUserFor(int userId) {
    if (!involvesUser(userId)) {
      return null;
    }
    return challengerId == userId ? opponent : challenger;
  }

  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progressRatio {
    if (challengerScore == 0 && opponentScore == 0) return 0.5;
    return challengerScore / (challengerScore + opponentScore);
  }
}

class DuelActionResult {
  final bool success;
  final String message;
  final DuelModel? duel;

  const DuelActionResult({
    required this.success,
    required this.message,
    this.duel,
  });
}

class DuelUserModel {
  final int id;
  final String name;
  final String? avatarUrl;

  const DuelUserModel({required this.id, required this.name, this.avatarUrl});

  factory DuelUserModel.fromJson(Map<String, dynamic> json) {
    return DuelUserModel(
      id: _DuelJsonParser.requiredInt(json, 'id'),
      name: json['name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class _DuelJsonParser {
  static int requiredInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    final parsed = _parseInt(value);
    if (parsed == null) {
      throw FormatException('`$key` alanı geçerli bir tam sayı değil: $value');
    }
    return parsed;
  }

  static int? nullableInt(Map<String, dynamic> json, String key) {
    return _parseInt(json[key]);
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      if (value.isFinite && value == value.roundToDouble()) {
        return value.toInt();
      }
      return null;
    }

    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return null;
      }

      return int.tryParse(normalized) ??
          (() {
            final parsedNum = num.tryParse(normalized);
            if (parsedNum != null &&
                parsedNum.isFinite &&
                parsedNum == parsedNum.roundToDouble()) {
              return parsedNum.toInt();
            }
            return null;
          })();
    }

    return null;
  }
}
