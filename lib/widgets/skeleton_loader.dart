import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, required this.width, required this.height, this.borderRadius = 12});

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: AppColors.skyBlue,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.lightBlue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: double.infinity, height: 140, borderRadius: 20),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(width: MediaQuery.of(context).size.width * 0.3, height: 14),
                const SizedBox(height: 8),
                SkeletonLoader(width: MediaQuery.of(context).size.width * 0.2, height: 12),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SkeletonLoader(width: 60, height: 32, borderRadius: 20),
                    const SizedBox(width: 8),
                    const SkeletonLoader(width: 60, height: 32, borderRadius: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
