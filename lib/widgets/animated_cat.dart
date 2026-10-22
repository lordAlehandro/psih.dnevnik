import 'package:flutter/material.dart';

class AnimatedCat extends StatefulWidget {
  const AnimatedCat({super.key});

  @override
  State<AnimatedCat> createState() => _AnimatedCatState();
}

class _AnimatedCatState extends State<AnimatedCat> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
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
        return Transform.translate(
          offset: Offset(0, -10 * _animation.value),
          child: Icon(
            Icons.pets,
            size: 100,
            color: Colors.orange,
          ),
        );
      },
    );
  }
}

class CatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    // Тело кота
    final bodyPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.4,
        size.width * 0.7,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.8,
        size.width * 0.3,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 0.4,
        size.width * 0.5,
        size.height * 0.3,
      );

    canvas.drawPath(bodyPath, paint);

    // Голова кота
    final headPath = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.25),
        radius: size.width * 0.15,
      ));

    canvas.drawPath(headPath, paint);

    // Уши
    final earPath = Path()
      ..moveTo(size.width * 0.4, size.height * 0.15)
      ..lineTo(size.width * 0.3, size.height * 0.05)
      ..lineTo(size.width * 0.5, size.height * 0.15)
      ..close();

    canvas.drawPath(earPath, paint);

    final earPath2 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.15)
      ..lineTo(size.width * 0.7, size.height * 0.05)
      ..lineTo(size.width * 0.5, size.height * 0.15)
      ..close();

    canvas.drawPath(earPath2, paint);

    // Глаза
    final eyePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.45, size.height * 0.2),
      size.width * 0.02,
      eyePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.2),
      size.width * 0.02,
      eyePaint,
    );

    // Нос
    final nosePath = Path()
      ..moveTo(size.width * 0.48, size.height * 0.25)
      ..lineTo(size.width * 0.52, size.height * 0.25)
      ..lineTo(size.width * 0.5, size.height * 0.27)
      ..close();

    canvas.drawPath(nosePath, eyePaint);

    // Усы
    final whiskerPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Левые усы
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.25),
      Offset(size.width * 0.2, size.height * 0.23),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.4, size.height * 0.27),
      Offset(size.width * 0.2, size.height * 0.27),
      whiskerPaint,
    );

    // Правые усы
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.25),
      Offset(size.width * 0.8, size.height * 0.23),
      whiskerPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.27),
      Offset(size.width * 0.8, size.height * 0.27),
      whiskerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 