import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RatingDialog extends StatefulWidget {
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  static const _ratingSubmittedKey = 'rating_submitted';

  const RatingDialog({
    super.key,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();

  static Future<bool> _isRatingSubmitted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_ratingSubmittedKey) ?? false;
  }

  static Future<void> show(BuildContext context) async {
    if (await _isRatingSubmitted()) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Rating dialog',
      pageBuilder: (context, animation, secondaryAnimation) => RatingDialog(
        onSubmit: () => Navigator.pop(context),
        onCancel: () => Navigator.pop(context),
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = Curves.easeOut.transform(animation.value);
        return FadeTransition(
          opacity: animation,
          child: Transform.scale(scale: 0.9 + (curved * 0.1), child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}

class _RatingDialogState extends State<RatingDialog> {
  int selectedRating = 0;
  final TextEditingController feedbackController = TextEditingController();
  bool isSubmitting = false;

  @override
  void dispose() {
    feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (selectedRating == 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => isSubmitting = true);

    // TODO: Send rating and feedback to your backend
    // Example: await ApiService.submitRating(selectedRating, feedbackController.text);

    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(RatingDialog._ratingSubmittedKey, true);

    if (mounted) {
      setState(() => isSubmitting = false);
      widget.onSubmit();
    }
  }

  Widget _buildStarRating() {
    const starCount = 5;
    const starSize = 36.0;
    const starContainerWidth = 220.0;

    void updateRating(Offset localPosition) {
      final newRating = ((localPosition.dx / starContainerWidth) * starCount)
          .clamp(0, starCount)
          .ceil();
      if (newRating != selectedRating) {
        setState(() => selectedRating = newRating);
      }
    }

    return SizedBox(
      width: starContainerWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) => updateRating(details.localPosition),
        onHorizontalDragUpdate: (details) =>
            updateRating(details.localPosition),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(starCount, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < selectedRating ? Icons.star : Icons.star_border,
                  color: index < selectedRating
                      ? Colors.amber.shade700
                      : Colors.grey,
                  size: starSize,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialDialog() {
    return AlertDialog(
      title: const Text(
        'How\'s Your Experience?',
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              'We\'d love to hear about your experience using our Todo App!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            _buildStarRating(),
            const SizedBox(height: 24),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your feedback (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSubmitting ? null : widget.onCancel,
          child: const Text('Skip'),
        ),
        ElevatedButton(
          onPressed: isSubmitting ? null : _submitRating,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF263238),
            foregroundColor: Colors.amber,
          ),
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildCupertinoDialog() {
    return CupertinoAlertDialog(
      title: const Text(
        'How\'s Your Experience?',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Text(
            'We\'d love to hear about your experience using our Todo App!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 20),
          _buildStarRating(),
          const SizedBox(height: 20),
          CupertinoTextField(
            controller: feedbackController,
            placeholder: 'Share your feedback (optional)',
            maxLines: 3,
            padding: const EdgeInsets.all(12),
          ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: isSubmitting ? null : widget.onCancel,
          child: const Text('Skip'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: isSubmitting ? null : _submitRating,
          child: isSubmitting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CupertinoActivityIndicator(),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS
        ? _buildCupertinoDialog()
        : _buildMaterialDialog();
  }
}
