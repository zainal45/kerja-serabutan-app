import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/user.dart';
import '../core/app_theme.dart';
import '../core/utils.dart';

class WorkerCard extends StatelessWidget {
  final User worker;
  final VoidCallback? onContact;
  final VoidCallback? onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    this.onContact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Avatar ────────────────────────────────────────────────────────
              _buildAvatar(),
              const SizedBox(width: 14),

              // ─── Info ──────────────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worker.name,
                            style: AppTheme.subtitle2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (worker.isOnline)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.statusOpen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: worker.rating,
                          itemBuilder: (_, __) =>
                              const Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          worker.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${worker.totalReviews} ulasan)',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Location & distance
                    if (worker.locationName != null || worker.distanceKm != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              _locationText,
                              style: AppTheme.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),

                    // Skills chips
                    if (worker.skills.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: worker.skills.take(3).map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ─── Contact Button ────────────────────────────────────────────────
              Column(
                children: [
                  const SizedBox(height: 2),
                  ElevatedButton(
                    onPressed: onContact,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Hubungi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _locationText {
    final parts = <String>[];
    if (worker.locationName != null) parts.add(worker.locationName!);
    if (worker.distanceKm != null) parts.add(formatDistance(worker.distanceKm));
    return parts.join(' • ');
  }

  Widget _buildAvatar() {
    final avatarUrl = worker.avatarUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        backgroundColor: AppTheme.backgroundGrey,
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
      child: Text(
        worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }
}
