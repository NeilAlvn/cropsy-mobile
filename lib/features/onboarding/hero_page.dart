/// A full-bleed onboarding hero: a natural photo or looping muted video up top,
/// with a brutalist content card (bordered, hard shadow) rising from the bottom
/// — the naturalism × brutalism mix. Used by the value-intro pages.
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../design/brutal.dart';
import '../../design/colors.dart';
import '../../design/components.dart';
import '../../design/typography.dart';

/// Background media for a hero — an asset image, optionally upgraded to a
/// looping video once it's ready (the image doubles as the video's poster).
class HeroMedia {
  const HeroMedia.image(this.image) : video = null;
  const HeroMedia.video(this.video, {required this.image});
  final String image; // asset path, always present (poster / fallback)
  final String? video; // asset path, optional

  bool get isVideo => video != null;
}

class HeroPage extends StatefulWidget {
  const HeroPage({
    super.key,
    required this.media,
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onNext,
    this.onSkip,
  });

  final HeroMedia media;
  final String kicker;
  final List<TextSpan> title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  State<HeroPage> createState() => _HeroPageState();
}

class _HeroPageState extends State<HeroPage> {
  VideoPlayerController? _video;

  @override
  void initState() {
    super.initState();
    final path = widget.media.video;
    if (path != null) {
      final c = VideoPlayerController.asset(path);
      _video = c;
      c.initialize().then((_) {
        c
          ..setLooping(true)
          ..setVolume(0)
          ..play();
        if (mounted) setState(() {});
      }).catchError((_) {
        // Fall back to the still poster if the clip can't load.
        if (mounted) setState(() => _video = null);
      });
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = _video;
    final videoReady = v != null && v.value.isInitialized;

    return Column(
      children: [
        // ── Full-bleed natural hero (photo, or looping video once ready) ──
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (videoReady)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: v.value.size.width,
                    height: v.value.size.height,
                    child: VideoPlayer(v),
                  ),
                )
              else
                Image.asset(widget.media.image, fit: BoxFit.cover),
              // Top scrim so the status bar / header stays legible over the photo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Color(0x40000000), Color(0x00000000)],
                  ),
                ),
              ),
            ],
          ),
        ),
        // ── Brutalist content card rising from the bottom ──
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(
              top: BorderSide(color: AppColors.border, width: Neo.borderWidth),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.kicker, style: AppText.kicker(context)),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      style: AppText.display(context).copyWith(fontSize: 30),
                      children: widget.title,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(widget.subtitle, style: AppText.bodyMuted(context)),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: widget.buttonLabel,
                    icon: Icons.arrow_forward,
                    onPressed: widget.onNext,
                  ),
                  if (widget.onSkip != null) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: TextButton(
                        onPressed: widget.onSkip,
                        child: Text('Already have an account? Sign in',
                            style: AppText.label(context,
                                color: AppColors.muted)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
