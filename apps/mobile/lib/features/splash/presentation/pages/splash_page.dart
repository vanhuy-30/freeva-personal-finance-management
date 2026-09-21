import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/splash_background.dart';
import '../widgets/splash_brand_content.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
      animationBehavior: AnimationBehavior.preserve,
    )..addStatusListener(_onStatus);
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SplashBackground(
        child: SizedBox.expand(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) => SplashBrandContent(
                    progress: _controller.value,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
