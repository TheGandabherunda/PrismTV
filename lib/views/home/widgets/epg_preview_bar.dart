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
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.unfocusedBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0xCC000000),
            blurRadius: 24,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Channel Info Block
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.liveRed,
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Text(
                    'LIVE BROADCAST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.liveRed,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                channel!.channelName,
                style: const TextStyle(
                  fontSize: 17,
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

          const SizedBox(width: 28),
          Container(width: 1, height: 44, color: AppColors.unfocusedBorder),
          const SizedBox(width: 28),

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
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '$startTimeStr - $endTimeStr',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: program?.progress ?? 0.35,
                      minHeight: 4,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    program?.description ?? 'Now broadcasting live on PrismTV network.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Action CTA (Watch Now)
          Focus(
            child: Builder(
              builder: (ctx) {
                final hasFocus = Focus.of(ctx).hasFocus;
                return InkWell(
                  onTap: onWatchTap,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: hasFocus ? AppColors.activeTabGradient : null,
                      color: hasFocus ? null : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasFocus ? AppColors.primary : AppColors.unfocusedBorder,
                        width: hasFocus ? 2 : 1,
                      ),
                      boxShadow: hasFocus
                          ? [
                              BoxShadow(
                                color: AppColors.primaryGlow,
                                blurRadius: 16,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 20,
                          color: hasFocus ? Colors.white : AppColors.primaryLight,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'WATCH [OK]',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: hasFocus ? Colors.white : AppColors.textPrimary,
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
