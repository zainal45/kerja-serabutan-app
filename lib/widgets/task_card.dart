import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/task.dart';
import '../core/app_theme.dart';
import '../core/routes.dart';
import '../core/utils.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap ??
            () => Navigator.pushNamed(context, AppRoutes.taskDetail,
                arguments: task.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Top Row: Category + Status ───────────────────────────────────
              Row(
                children: [
                  _buildCategoryBadge(),
                  const Spacer(),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 10),

              // ─── Title ────────────────────────────────────────────────────────
              Text(
                task.title,
                style: AppTheme.subtitle1,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // ─── Budget ───────────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.payments_outlined,
                      size: 16, color: AppTheme.accentOrange),
                  const SizedBox(width: 4),
                  Text(
                    formatBudgetRange(task.budgetMin, task.budgetMax),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ─── Location + Distance ──────────────────────────────────────────
              if (task.locationAddress != null || task.distanceKm != null)
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _buildLocationText(),
                        style: AppTheme.body2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ─── Client Info + Time ───────────────────────────────────────────
              Row(
                children: [
                  _buildClientAvatar(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.client?.name ?? 'Pengguna',
                          style: AppTheme.body2.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (task.client != null && task.client!.totalReviews > 0)
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: task.client!.rating,
                                itemBuilder: (_, __) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${task.client!.totalReviews})',
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Text(
                    timeago.format(task.createdAt, locale: 'id'),
                    style: AppTheme.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildLocationText() {
    final parts = <String>[];
    if (task.locationAddress != null) parts.add(task.locationAddress!);
    if (task.distanceKm != null) parts.add(formatDistance(task.distanceKm));
    return parts.join(' • ');
  }

  Widget _buildCategoryBadge() {
    final category = task.category ?? 'lainnya';
    final color = AppTheme.categoryColors[category] ?? AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCategoryIcon(category), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            getCategoryLabel(category),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    switch (task.status) {
      case 'open':
        color = AppTheme.statusOpen;
        break;
      case 'negotiating':
        color = AppTheme.statusNegotiating;
        break;
      case 'in_progress':
        color = AppTheme.statusInProgress;
        break;
      case 'completed':
        color = AppTheme.statusCompleted;
        break;
      default:
        color = AppTheme.statusCancelled;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        getStatusLabel(task.status),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildClientAvatar() {
    final name = task.client?.name ?? '?';
    final avatarUrl = task.client?.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
        backgroundColor: AppTheme.backgroundGrey,
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppTheme.primaryBlueLight.withOpacity(0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'bersih-bersih':
        return Icons.cleaning_services_outlined;
      case 'pindahan':
        return Icons.local_shipping_outlined;
      case 'servis':
        return Icons.build_outlined;
      case 'tukang':
        return Icons.handyman_outlined;
      case 'kurir':
        return Icons.delivery_dining_outlined;
      default:
        return Icons.work_outline;
    }
  }
}
