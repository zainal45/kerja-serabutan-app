import 'user.dart';

class Task {
  final String id;
  final String title;
  final String status;
  final String? description;
  final String? category;
  final String? locationAddress;
  final double? budgetMin;
  final double? budgetMax;
  final double? finalPrice;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final String clientId;
  final User? client;
  final User? worker;
  final DateTime createdAt;
  final DateTime? scheduledAt;
  final int applicationCount;

  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.clientId,
    required this.createdAt,
    this.description,
    this.category,
    this.locationAddress,
    this.budgetMin,
    this.budgetMax,
    this.finalPrice,
    this.lat,
    this.lng,
    this.distanceKm,
    this.client,
    this.worker,
    this.scheduledAt,
    this.applicationCount = 0,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    User? parseUser(dynamic raw) {
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) return User.fromJson(raw);
      return null;
    }

    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      if (raw is String) return DateTime.tryParse(raw) ?? DateTime.now();
      return DateTime.now();
    }

    // Handle both nested location object and flat lat/lng
    double? parseLat(Map<String, dynamic> j) {
      if (j['lat'] != null) return (j['lat'] as num).toDouble();
      if (j['location'] is Map) {
        final coords = j['location']['coordinates'];
        if (coords is List && coords.length >= 2) {
          return (coords[1] as num).toDouble();
        }
      }
      return null;
    }

    double? parseLng(Map<String, dynamic> j) {
      if (j['lng'] != null) return (j['lng'] as num).toDouble();
      if (j['location'] is Map) {
        final coords = j['location']['coordinates'];
        if (coords is List && coords.length >= 2) {
          return (coords[0] as num).toDouble();
        }
      }
      return null;
    }

    return Task(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      description: json['description']?.toString(),
      category: json['category']?.toString(),
      locationAddress: json['locationAddress']?.toString() ??
          json['location']?['address']?.toString(),
      budgetMin: (json['budgetMin'] as num?)?.toDouble(),
      budgetMax: (json['budgetMax'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      lat: parseLat(json),
      lng: parseLng(json),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble(),
      clientId:
          json['clientId']?.toString() ?? json['client']?['_id']?.toString() ?? '',
      client: parseUser(json['client']),
      worker: parseUser(json['worker']),
      createdAt: parseDate(json['createdAt']),
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'].toString())
          : null,
      applicationCount: (json['applicationCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'status': status,
        'clientId': clientId,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        if (locationAddress != null) 'locationAddress': locationAddress,
        if (budgetMin != null) 'budgetMin': budgetMin,
        if (budgetMax != null) 'budgetMax': budgetMax,
        if (finalPrice != null) 'finalPrice': finalPrice,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'createdAt': createdAt.toIso8601String(),
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
      };

  bool get isOpen => status == 'open';
  bool get isNegotiating => status == 'negotiating';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  @override
  bool operator ==(Object other) => other is Task && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Task(id: $id, title: $title, status: $status)';
}

class TaskApplication {
  final String id;
  final String taskId;
  final String workerId;
  final User? worker;
  final double proposedPrice;
  final String? message;
  final String status;
  final DateTime createdAt;

  const TaskApplication({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.proposedPrice,
    required this.status,
    required this.createdAt,
    this.worker,
    this.message,
  });

  factory TaskApplication.fromJson(Map<String, dynamic> json) {
    return TaskApplication(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      taskId: json['taskId']?.toString() ?? '',
      workerId: json['workerId']?.toString() ??
          json['worker']?['_id']?.toString() ?? '',
      worker: json['worker'] is Map<String, dynamic>
          ? User.fromJson(json['worker'] as Map<String, dynamic>)
          : null,
      proposedPrice: (json['proposedPrice'] as num?)?.toDouble() ?? 0,
      message: json['message']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
