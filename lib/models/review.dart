import 'user.dart';

class Review {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final String taskId;
  final int rating;
  final String? comment;
  final User? reviewer;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.taskId,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.reviewer,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      reviewerId: json['reviewerId']?.toString() ??
          json['reviewer']?['_id']?.toString() ?? '',
      revieweeId: json['revieweeId']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment']?.toString(),
      reviewer: json['reviewer'] is Map<String, dynamic>
          ? User.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reviewerId': reviewerId,
        'revieweeId': revieweeId,
        'taskId': taskId,
        'rating': rating,
        if (comment != null) 'comment': comment,
      };

  @override
  bool operator ==(Object other) => other is Review && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
