import 'package:flutter/material.dart';
import '../models/daily_w_message.dart';

/// The hero card that displays the current Daily W message
/// with Like / Dislike / Favorite / Share actions.
class MessageCard extends StatelessWidget {
  final DailyWMessage message;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final bool isFavorited;

  const MessageCard({
    super.key,
    required this.message,
    required this.onLike,
    required this.onDislike,
    required this.onFavorite,
    required this.onShare,
    this.isFavorited = false,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement full card UI
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.text,
                style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(icon: const Icon(Icons.thumb_up_outlined), onPressed: onLike),
                IconButton(icon: const Icon(Icons.thumb_down_outlined), onPressed: onDislike),
                IconButton(
                  icon: Icon(isFavorited ? Icons.star : Icons.star_border),
                  onPressed: onFavorite,
                ),
                IconButton(icon: const Icon(Icons.share_outlined), onPressed: onShare),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
