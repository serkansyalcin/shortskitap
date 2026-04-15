class DuelModel {
  final int id;
  final int challengerId;
  final int? challengerReaderProfileId;
  final int opponentId;
  final int? opponentReaderProfileId;
  final String profileType;
  final String status;
  final int challengerScore;
  final int opponentScore;
  final int pointsAtStake;
  final int? winnerId;
  final int? winnerReaderProfileId;
  final DateTime? startsAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DuelUserModel? challenger;
  final DuelUserModel? opponent;
  final DuelUserModel? winner;

  const DuelModel({
    required this.id,
    required this.challengerId,
    this.challengerReaderProfileId,
    required this.opponentId,
    this.opponentReaderProfileId,
    this.profileType = 'parent',
    required this.status,
    required this.challengerScore,
    required this.opponentScore,
    required this.pointsAtStake,
    this.winnerId,
    this.winnerReaderProfileId,
    this.startsAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.challenger,
    this.opponent,
    this.winner,
  });

  factory DuelModel.fromJson(Map<String, dynamic> json) {
    return DuelModel(
      id: _DuelJsonParser.requiredInt(json, 'id'),
      challengerId: _DuelJsonParser.requiredInt(json, 'challenger_id'),
      challengerReaderProfileId: _DuelJsonParser.nullableInt(
        json,
        'challenger_reader_profile_id',
      ),
      opponentId: _DuelJsonParser.requiredInt(json, 'opponent_id'),
      opponentReaderProfileId: _DuelJsonParser.nullableInt(
        json,
        'opponent_reader_profile_id',
      ),
      profileType: json['profile_type'] as String? ?? 'parent',
      status: json['status'] as String,
      challengerScore: _DuelJsonParser.requiredInt(json, 'challenger_score'),
      opponentScore: _DuelJsonParser.requiredInt(json, 'opponent_score'),
      pointsAtStake: _DuelJsonParser.requiredInt(json, 'points_at_stake'),
      winnerId: _DuelJsonParser.nullableInt(json, 'winner_id'),
      winnerReaderProfileId: _DuelJsonParser.nullableInt(
        json,
        'winner_reader_profile_id',
      ),
      startsAt: json['starts_at'] != null
          ? DateTime.parse(json['starts_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      challenger: json['challenger'] != null
          ? DuelUserModel.fromJson(json['challenger'] as Map<String, dynamic>)
          : null,
      opponent: json['opponent'] != null
          ? DuelUserModel.fromJson(json['opponent'] as Map<String, dynamic>)
          : null,
      winner: json['winner'] != null
          ? DuelUserModel.fromJson(json['winner'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isExpired => status == 'expired';
  bool get isDeclined => status == 'declined';
  bool get isOpen => isPending || isActive;
  bool get hasReaderProfileScope =>
      challengerReaderProfileId != null || opponentReaderProfileId != null;
  bool get isTie => challengerScore == opponentScore;
  bool get challengerWon => challengerScore > opponentScore;
  bool get opponentWon => opponentScore > challengerScore;
  int get scoreGap => (challengerScore - opponentScore).abs();
  DuelUserModel? get leadingUser => challengerWon
      ? challenger
      : opponentWon
      ? opponent
      : null;
  DateTime? get resolvedEndedAt => isCompleted || isDeclined || isExpired
      ? (updatedAt ?? expiresAt ?? startsAt ?? createdAt)
      : null;

  bool involvesUser(int userId) {
    return challengerId == userId || opponentId == userId;
  }

  bool involvesReaderProfile(int readerProfileId) {
    return challengerReaderProfileId == readerProfileId ||
        opponentReaderProfileId == readerProfileId;
  }

  bool isIncomingFor(int userId) {
    return isPending && opponentId == userId;
  }

  bool isIncomingForReaderProfile(int readerProfileId) {
    return isPending && opponentReaderProfileId == readerProfileId;
  }

  bool isOutgoingFor(int userId) {
    return isPending && challengerId == userId;
  }

  bool isOutgoingForReaderProfile(int readerProfileId) {
    return isPending && challengerReaderProfileId == readerProfileId;
  }

  int? otherUserIdFor(int userId) {
    if (!involvesUser(userId)) {
      return null;
    }
    return challengerId == userId ? opponentId : challengerId;
  }

  int? otherReaderProfileIdFor(int readerProfileId) {
    if (!involvesReaderProfile(readerProfileId)) {
      return null;
    }
    return challengerReaderProfileId == readerProfileId
        ? opponentReaderProfileId
        : challengerReaderProfileId;
  }

  DuelUserModel? otherUserFor(int userId) {
    if (!involvesUser(userId)) {
      return null;
    }
    return challengerId == userId ? opponent : challenger;
  }

  DuelUserModel? otherUserForReaderProfile(int readerProfileId) {
    if (!involvesReaderProfile(readerProfileId)) {
      return null;
    }
    return challengerReaderProfileId == readerProfileId ? opponent : challenger;
  }

  bool isIncomingForActor({int? userId, int? readerProfileId}) {
    if (hasReaderProfileScope && readerProfileId != null) {
      return isIncomingForReaderProfile(readerProfileId);
    }

    return userId != null && isIncomingFor(userId);
  }

  bool isOutgoingForActor({int? userId, int? readerProfileId}) {
    if (hasReaderProfileScope && readerProfileId != null) {
      return isOutgoingForReaderProfile(readerProfileId);
    }

    return userId != null && isOutgoingFor(userId);
  }

  DuelUserModel? otherUserForActor({int? userId, int? readerProfileId}) {
    if (hasReaderProfileScope && readerProfileId != null) {
      return otherUserForReaderProfile(readerProfileId);
    }

    return userId == null ? null : otherUserFor(userId);
  }

  bool isActorChallenger({int? userId, int? readerProfileId}) {
    if (hasReaderProfileScope && readerProfileId != null) {
      return challengerReaderProfileId == readerProfileId;
    }

    return userId != null && challengerId == userId;
  }

  bool isActorOpponent({int? userId, int? readerProfileId}) {
    if (hasReaderProfileScope && readerProfileId != null) {
      return opponentReaderProfileId == readerProfileId;
    }

    return userId != null && opponentId == userId;
  }

  bool didActorWin({int? userId, int? readerProfileId}) {
    if (isTie) {
      return false;
    }

    if (winnerId != null || winnerReaderProfileId != null) {
      if (hasReaderProfileScope && readerProfileId != null) {
        return winnerReaderProfileId == readerProfileId;
      }

      return userId != null && winnerId == userId;
    }

    return isActorChallenger(userId: userId, readerProfileId: readerProfileId)
        ? challengerWon
        : isActorOpponent(userId: userId, readerProfileId: readerProfileId)
        ? opponentWon
        : false;
  }

  bool didActorLose({int? userId, int? readerProfileId}) {
    if (isTie) {
      return false;
    }

    if (!isActorChallenger(userId: userId, readerProfileId: readerProfileId) &&
        !isActorOpponent(userId: userId, readerProfileId: readerProfileId)) {
      return false;
    }

    return !didActorWin(userId: userId, readerProfileId: readerProfileId);
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
  final int? readerProfileId;
  final String name;
  final String username;
  final String? avatarUrl;

  const DuelUserModel({
    required this.id,
    this.readerProfileId,
    required this.name,
    required this.username,
    this.avatarUrl,
  });

  factory DuelUserModel.fromJson(Map<String, dynamic> json) {
    return DuelUserModel(
      id: _DuelJsonParser.requiredInt(json, 'id'),
      readerProfileId: _DuelJsonParser.nullableInt(json, 'reader_profile_id'),
      name: json['name'] as String,
      username: json['username'] as String? ?? '',
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
