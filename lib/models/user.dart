class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? locationName;
  final String? role;
  final List<String> skills;
  final double rating;
  final int totalReviews;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final bool isOnline;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.locationName,
    this.role,
    this.skills = const [],
    this.rating = 0.0,
    this.totalReviews = 0,
    this.lat,
    this.lng,
    this.distanceKm,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> parseSkills(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return [];
    }

    return User(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      bio: json['bio']?.toString(),
      locationName: json['locationName']?.toString() ??
          json['location']?['name']?.toString(),
      role: json['role']?.toString(),
      skills: parseSkills(json['skills']),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ??
          (json['distance'] as num?)?.toDouble(),
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        if (phone != null) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (bio != null) 'bio': bio,
        if (locationName != null) 'locationName': locationName,
        if (role != null) 'role': role,
        'skills': skills,
        'rating': rating,
        'totalReviews': totalReviews,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    String? bio,
    String? locationName,
    String? role,
    List<String>? skills,
    double? rating,
    int? totalReviews,
    double? lat,
    double? lng,
    double? distanceKm,
    bool? isOnline,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      locationName: locationName ?? this.locationName,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      distanceKm: distanceKm ?? this.distanceKm,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  bool operator ==(Object other) => other is User && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}
