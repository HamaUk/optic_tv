import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/viewer_service.dart';

class LiveViewerBadge extends ConsumerWidget {
  final String channelName;
  final bool isMobile;

  const LiveViewerBadge({
    super.key,
    required this.channelName,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewersAsync = ref.watch(channelViewersProvider(channelName));
    int viewers = viewersAsync.value ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.remove_red_eye_rounded,
            color: Color(0xFFD4AF37),
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            '$viewers',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
