import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/channel_model.dart';
import '../../../data/models/epg_program_model.dart';

class EpgPreviewBar extends StatelessWidget {
  final ChannelModel? channel;
  final EpgProgramModel? program;
  final bool isLoading;
  final VoidCallback onWatchTap;

  const EpgPreviewBar({
    super.key,
    required this.channel,
    required this.program,
    required this.isLoading,
    required this.onWatchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (channel == null) return const SizedBox.shrink();

    final timeFormatter = DateFormat('hh:mm a');
    final startTimeStr = program != null ? timeFormatter.format(program!.startTime) : '--:--';
    final endTimeStr = program != null ? timeFormatter.format(program!.endTime) : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.unfocusedBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Channel Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                channel!.channelName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '${channel!.categoryName} • ${channel!.languageName}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(width: 32),
          Container(width: 1, height: 50, color: AppColors.unfocusedBorder),
          const SizedBox(width: 32),

          // Program Details & Timeline
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          program?.showName ?? 'Live Broadcast',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '$startTimeStr - $endTimeStr',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: program?.progress ?? 0.3,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    program?.description ?? 'Now playing on PrismTV live network.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 24),

          // Watch Now Button Hint
          Focus(
            child: Builder(
              builder: (ctx) {
                final hasFocus = Focus.of(ctx).hasFocus;
                return InkWell(
                  onTap: onWatchTap,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: hasFocus ? AppColors.prismGradient : null,
                      color: hasFocus ? null : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                        width: hasFocus ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                          color: hasFocus ? Colors.black : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'WATCH [OK]',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: hasFocus ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

