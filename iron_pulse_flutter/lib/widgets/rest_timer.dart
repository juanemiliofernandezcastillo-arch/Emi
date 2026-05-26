import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../store.dart';

class RestTimerWidget extends StatelessWidget {
  const RestTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<WorkoutStore>();

    if (!store.isRestActive) {
      return const SizedBox.shrink();
    }

    final double progress = store.restTotal > 0 
        ? store.restRemaining / store.restTotal 
        : 0.0;

    final String minutes = (store.restRemaining ~/ 60).toString().padLeft(2, '0');
    final String seconds = (store.restRemaining % 60).toString().padLeft(2, '0');

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SlideTransitionWidget(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CyberTheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: CyberTheme.cyberTeal.withOpacity(0.3), width: 1.5),
            boxShadow: CyberTheme.neonGlow(color: CyberTheme.cyberTeal, opacity: 0.15, blurRadius: 10),
          ),
          child: Row(
            children: [
              // Circular Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: CyberTheme.borderTranslucent,
                      color: CyberTheme.cyberTeal,
                      strokeWidth: 4,
                    ),
                  ),
                  Text(
                    seconds,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: CyberTheme.cyberTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              
              // Timer Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "DESCANSANDO",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: CyberTheme.cyberTeal,
                        letterSpacing: 1.5
                      ),
                    ),
                    Text(
                      "$minutes:$seconds",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Control Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // -30s
                  IconButton(
                    icon: const Icon(Icons.remove, color: CyberTheme.textSecondary, size: 20),
                    onPressed: () => store.adjustTimer(-30),
                    style: IconButton.styleFrom(
                      backgroundColor: CyberTheme.inputBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  
                  // +30s
                  IconButton(
                    icon: const Icon(Icons.add, color: CyberTheme.cyberTeal, size: 20),
                    onPressed: () => store.adjustTimer(30),
                    style: IconButton.styleFrom(
                      backgroundColor: CyberTheme.inputBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Skip
                  ElevatedButton(
                    onPressed: () => store.cancelRestTimer(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CyberTheme.neonRose,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "SALTAR",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Simple slide-up transition animation wrapper
class SlideTransitionWidget extends StatefulWidget {
  final Widget child;

  const SlideTransitionWidget({super.key, required this.child});

  @override
  State<SlideTransitionWidget> createState() => _SlideTransitionWidgetState();
}

class _SlideTransitionWidgetState extends State<SlideTransitionWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}
