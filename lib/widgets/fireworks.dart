import 'dart:math';
import 'package:flutter/material.dart';

class Firework extends StatefulWidget {
  final Widget child;
  const Firework({super.key, required this.child});

  @override
  State<Firework> createState() => _FireworkState();
}

class _FireworkState extends State<Firework> with TickerProviderStateMixin {
  final List<FireworkParticle> _particles = [];
  final Random random = Random();

  void _createParticles(Offset position) {
    const numberOfParticles = 30;
    for (var i = 0; i < numberOfParticles; i++) {
      final angle = 2 * pi * i / numberOfParticles;
      final velocity = 2.0 + random.nextDouble() * 2.0;
      final color = Colors.primaries[random.nextInt(Colors.primaries.length)];
      
      late final FireworkParticle particle;
      particle = FireworkParticle(
        position: position,
        angle: angle,
        velocity: velocity,
        color: color,
        controller: AnimationController(
          duration: const Duration(milliseconds: 1000),
          vsync: this,
        )..forward()..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            setState(() {
              _particles.remove(particle);
            });
          }
        }),
      );
      
      setState(() {
        _particles.add(particle);
      });
    }
  }

  @override
  void dispose() {
    for (var particle in _particles) {
      particle.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _createParticles(details.localPosition),
      child: Stack(
        children: [
          widget.child,
          ...(_particles.map((particle) => AnimatedBuilder(
            animation: particle.controller,
            builder: (context, child) {
              final progress = particle.controller.value;
              final dx = particle.position.dx +
                  cos(particle.angle) * particle.velocity * progress * 100;
              final dy = particle.position.dy +
                  sin(particle.angle) * particle.velocity * progress * 100 +
                  2 * progress * progress * 100;
              
              return Positioned(
                left: dx - 2,
                top: dy - 2,
                child: Opacity(
                  opacity: 1 - progress,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: particle.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: particle.color.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ))),
        ],
      ),
    );
  }
}

class FireworkParticle {
  final Offset position;
  final double angle;
  final double velocity;
  final Color color;
  final AnimationController controller;

  FireworkParticle({
    required this.position,
    required this.angle,
    required this.velocity,
    required this.color,
    required this.controller,
  });
} 