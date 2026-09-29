import 'package:flutter/material.dart';

import 'gospel_ad.dart';

class GospelAdScreen extends StatefulWidget {
  final GospelAd ad;

  const GospelAdScreen({super.key, required this.ad});

  /// Shows the gospel ad as a full-screen route.
  /// Returns true if the user dismissed via the X button (reward earned),
  /// false if the route was popped any other way (no reward).
  static Future<bool> show(NavigatorState navigator, GospelAd ad) async {
    final result = await navigator.push<bool>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return GospelAdScreen(ad: ad);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
    return result == true;
  }

  @override
  State<GospelAdScreen> createState() => _GospelAdScreenState();
}

class _GospelAdScreenState extends State<GospelAdScreen>
    with TickerProviderStateMixin {
  late List<AnimationController> _lineControllers;
  late List<Animation<double>> _lineFades;
  late AnimationController _closeButtonController;
  late Animation<double> _closeButtonFade;
  bool _closeButtonVisible = false;

  static const _fadeDuration = Duration(milliseconds: 1200);
  static const _totalTextDuration = Duration(seconds: 14);

  @override
  void initState() {
    super.initState();
    _buildAnimations();
    _startSequence();
  }

  void _buildAnimations() {
    final lineCount = widget.ad.lines.length;
    _lineControllers = List.generate(
      lineCount,
      (_) => AnimationController(vsync: this, duration: _fadeDuration),
    );
    _lineFades = _lineControllers.map((c) {
      return CurvedAnimation(parent: c, curve: Curves.easeIn);
    }).toList();

    _closeButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _closeButtonFade =
        CurvedAnimation(parent: _closeButtonController, curve: Curves.easeIn);
  }

  void _startSequence() {
    final lineCount = widget.ad.lines.length;

    // Distribute fade-ins across the text duration window.
    final availableMs = _totalTextDuration.inMilliseconds;
    final intervalMs =
        lineCount > 1 ? (availableMs / lineCount).round() : availableMs;

    const initialDelayMs = 800;

    for (int i = 0; i < lineCount; i++) {
      final delay = Duration(milliseconds: initialDelayMs + i * intervalMs);
      Future.delayed(delay, () {
        if (mounted) _lineControllers[i].forward();
      });
    }

    // Show the close button after all lines have finished fading in.
    final lastLineStartMs = initialDelayMs + (lineCount - 1) * intervalMs;
    final closeButtonDelayMs = lastLineStartMs + _fadeDuration.inMilliseconds;

    Future.delayed(Duration(milliseconds: closeButtonDelayMs), () {
      if (mounted) {
        setState(() => _closeButtonVisible = true);
        _closeButtonController.forward();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _lineControllers) {
      c.dispose();
    }
    _closeButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < widget.ad.lines.length; i++) ...[
                        if (i > 0) const SizedBox(height: 28),
                        FadeTransition(
                          opacity: _lineFades[i],
                          child: Text(
                            widget.ad.lines[i],
                            textAlign: TextAlign.center,
                            style: _styleForLine(i),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (_closeButtonVisible)
              Positioned(
                top: topPadding + 12,
                right: 12,
                child: FadeTransition(
                  opacity: _closeButtonFade,
                  child: IconButton(
                    iconSize: 32,
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  TextStyle _styleForLine(int index) {
    final line = widget.ad.lines[index];
    final isReference = line.startsWith('—');
    final isLast = index == widget.ad.lines.length - 1;

    if (isReference) {
      return const TextStyle(
        color: Colors.white70,
        fontSize: 16,
        fontStyle: FontStyle.italic,
        height: 1.6,
      );
    }

    if (isLast && !isReference) {
      return const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.6,
        letterSpacing: 0.5,
      );
    }

    return const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w300,
      height: 1.6,
    );
  }
}
