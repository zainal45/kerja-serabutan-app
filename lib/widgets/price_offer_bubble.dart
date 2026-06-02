import 'package:flutter/material.dart';
import '../models/message.dart';
import '../core/app_theme.dart';
import '../core/utils.dart';

class PriceOfferBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  final void Function(String status)? onRespond;

  const PriceOfferBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMine ? 60 : 12,
        right: isMine ? 12 : 60,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              border: Border.all(
                color: _borderColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ────────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: _headerColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer_outlined,
                          size: 16, color: _headerTextColor),
                      const SizedBox(width: 6),
                      Text(
                        'Tawaran Harga',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _headerTextColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Price ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatRupiah(message.offerPrice ?? 0),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _priceColor,
                        ),
                      ),
                      if (message.content.isNotEmpty &&
                          message.content != 'offer')
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            message.content,
                            style: AppTheme.body2,
                          ),
                        ),
                      const SizedBox(height: 12),

                      // ─── Status ────────────────────────────────────────────────
                      _buildStatusWidget(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusWidget(BuildContext context) {
    switch (message.offerStatus) {
      case 'accepted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                  size: 14, color: AppTheme.success),
              const SizedBox(width: 6),
              const Text(
                'Tawaran Diterima',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        );

      case 'rejected':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.error.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_outlined, size: 14, color: AppTheme.error),
              const SizedBox(width: 6),
              const Text(
                'Tawaran Ditolak',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
        );

      default:
        // Pending — show accept/reject buttons only if not sender
        if (isMine || onRespond == null) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.access_time, size: 14, color: AppTheme.warning),
                SizedBox(width: 6),
                Text(
                  'Menunggu respons',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onRespond!('rejected'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Tolak',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onRespond!('accepted'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Terima',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
    }
  }

  Color get _borderColor {
    switch (message.offerStatus) {
      case 'accepted':
        return AppTheme.success.withValues(alpha: 0.4);
      case 'rejected':
        return AppTheme.error.withValues(alpha: 0.4);
      default:
        return AppTheme.accentOrange.withValues(alpha: 0.4);
    }
  }

  Color get _headerColor {
    switch (message.offerStatus) {
      case 'accepted':
        return AppTheme.success.withValues(alpha: 0.12);
      case 'rejected':
        return AppTheme.error.withValues(alpha: 0.12);
      default:
        return AppTheme.accentOrange.withValues(alpha: 0.12);
    }
  }

  Color get _headerTextColor {
    switch (message.offerStatus) {
      case 'accepted':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.error;
      default:
        return AppTheme.accentOrange;
    }
  }

  Color get _priceColor {
    switch (message.offerStatus) {
      case 'accepted':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textPrimary;
    }
  }
}
