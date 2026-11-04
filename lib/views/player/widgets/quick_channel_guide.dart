import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/channel_model.dart';

class QuickChannelGuide extends StatelessWidget {
  final List<ChannelModel> channels;
  final ChannelModel activeChannel;
  final ValueChanged<ChannelModel> onSelect;
  final VoidCallback onClose;

  const QuickChannelGuide({
    super.key,
    required this.channels,
    required this.activeChannel,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(right: BorderSide(color: AppColors.unfocusedBorder)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'QUICK CHANNELS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.unfocusedBorder),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: channels.length,
              itemBuilder: (context, index) {
                final channel = channels[index];
                final isActive = channel.channelId == activeChannel.channelId;

                return Focus(
                  child: Builder(
                    builder: (ctx) {
                      final hasFocus = Focus.of(ctx).hasFocus;
                      return InkWell(
                        onTap: () => onSelect(channel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          color: hasFocus
                              ? AppColors.focusedBackground
                              : (isActive ? AppColors.primaryGlow : Colors.transparent),
                          child: Row(
                            children: [
                              if (isActive)
                                const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 16)
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  channel.channelName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isActive || hasFocus ? FontWeight.bold : FontWeight.w500,
                                    color: isActive
                                        ? AppColors.primary
                                        : (hasFocus ? Colors.white : AppColors.textPrimary),
                                  ),
                                ),
                              ),
                              if (channel.isHd)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'HD',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
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

