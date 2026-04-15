import 'dart:convert';

class InteractiveElementModel {
  final int id;
  final String type;
  final Map<String, dynamic> payload;
  final int rewardPoints;

  const InteractiveElementModel({
    required this.id,
    required this.type,
    required this.payload,
    required this.rewardPoints,
  });

  factory InteractiveElementModel.fromJson(Map<String, dynamic> json) {
    dynamic payloadData = json['payload'];
    if (payloadData is String) {
      payloadData = jsonDecode(payloadData);
    }

    return InteractiveElementModel(
      id: json['id'] as int,
      type: json['type'] as String,
      payload: payloadData as Map<String, dynamic>? ?? {},
      rewardPoints: json['reward_points'] as int? ?? 0,
    );
  }
}
