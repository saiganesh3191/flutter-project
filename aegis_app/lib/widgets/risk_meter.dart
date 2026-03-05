import 'package:flutter/material.dart';
import 'dart:math' as math;

class RiskMeter extends StatefulWidget {
  final int riskScore;
  final String status;

  const RiskMeter({
    super.key,
    required this.riskScore,
    required this.status,
  });

  @override
  State<RiskMeter> createState() => _RiskMeterState();
}

class _RiskMeterState extends State<RiskMeter> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentScore = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.riskScore.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    
    _animation.addListener(() {
      setState(() {
        _currentScore = _animation.value;
      });
    });
  }

  @override
  void didUpdateWidget(RiskMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.riskScore != widget.riskScore) {
      _animation = Tween<double>(
        begin: _currentScore,
        end: widget.riskScore.toDouble(),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColorForScore(double score) {
    if (score < 20) return Colors.green;
    if (score < 40) return Colors.lightGreen;
    if (score < 60) return Colors.orange;
    if (score < 80) return Colors.deepOrange;
    return Colors.red;
  }

  String _getLabelForScore(double score) {
    if (score < 20) return 'LOW';
    if (score < 40) return 'MODERATE';
    if (score < 70) return 'HIGH';
    return 'SEVERE';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          const Text(
            'RISK METER',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // Gauge
          SizedBox(
            height: 250,
            child: CustomPaint(
              painter: RiskMeterPainter(
                score: _currentScore,
                color: _getColorForScore(_currentScore),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),
                    const Text(
                      'RISK SCORE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_currentScore.toInt()}',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: _getColorForScore(_currentScore),
                        shadows: [
                          Shadow(
                            color: _getColorForScore(_currentScore).withOpacity(0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLabel('LOW', Colors.green, _currentScore < 20),
              _buildLabel('MODERATE', Colors.orange, _currentScore >= 20 && _currentScore < 40),
              _buildLabel('HIGH', Colors.deepOrange, _currentScore >= 40 && _currentScore < 70),
              _buildLabel('SEVERE', Colors.red, _currentScore >= 70),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, Color color, bool isActive) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? color : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class RiskMeterPainter extends CustomPainter {
  final double score;
  final Color color;

  RiskMeterPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.75);
    final radius = size.width * 0.4;

    // Draw outer circle (black background)
    final outerPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 20),
      math.pi,
      math.pi,
      true,
      outerPaint,
    );

    // Draw gradient arc background
    final gradientColors = [
      Colors.green,
      Colors.lightGreen,
      Colors.yellow,
      Colors.orange,
      Colors.deepOrange,
      Colors.red,
    ];

    for (int i = 0; i < 100; i++) {
      final angle = math.pi * (i / 100);
      final colorIndex = (i / 100 * (gradientColors.length - 1)).floor();
      final nextColorIndex = math.min(colorIndex + 1, gradientColors.length - 1);
      final t = (i / 100 * (gradientColors.length - 1)) - colorIndex;
      final segmentColor = Color.lerp(
        gradientColors[colorIndex],
        gradientColors[nextColorIndex],
        t,
      )!;

      final paint = Paint()
        ..color = segmentColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi + angle,
        math.pi / 100,
        false,
        paint,
      );
    }

    // Draw active arc (filled based on score)
    final activeAngle = math.pi * (score / 100);
    final activePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.8),
          color,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      activeAngle,
      false,
      activePaint,
    );

    // Draw tick marks
    for (int i = 0; i <= 10; i++) {
      final angle = math.pi + (math.pi * i / 10);
      final startRadius = radius - 15;
      final endRadius = radius + 5;

      final start = Offset(
        center.dx + startRadius * math.cos(angle),
        center.dy + startRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + endRadius * math.cos(angle),
        center.dy + endRadius * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = i % 2 == 0 ? 3 : 2;

      canvas.drawLine(start, end, tickPaint);

      // Draw numbers
      if (i % 2 == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i * 10}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();

        final textOffset = Offset(
          center.dx + (radius + 20) * math.cos(angle) - textPainter.width / 2,
          center.dy + (radius + 20) * math.sin(angle) - textPainter.height / 2,
        );

        textPainter.paint(canvas, textOffset);
      }
    }

    // Draw needle
    final needleAngle = math.pi + (math.pi * score / 100);
    final needleLength = radius - 10;

    final needlePath = Path();
    needlePath.moveTo(center.dx, center.dy);
    needlePath.lineTo(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(needlePath, needlePaint);

    // Draw center circle
    final centerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12, centerCirclePaint);

    final centerDotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, centerDotPaint);

    // Draw inner shadow circle
    final innerCirclePaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 40),
      0,
      math.pi * 2,
      true,
      innerCirclePaint,
    );
  }

  @override
  bool shouldRepaint(RiskMeterPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
