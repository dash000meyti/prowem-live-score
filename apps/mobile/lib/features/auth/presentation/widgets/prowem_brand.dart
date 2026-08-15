import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class ProwemBrand extends StatelessWidget {
  const ProwemBrand({this.compact = false, this.horizontal = false, super.key});

  final bool compact;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final label = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          horizontal ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text('PROWEM',
            style: TextStyle(
                fontSize:
                    horizontal ? (compact ? 24 : 32) : (compact ? 38 : 52),
                height: .8,
                fontWeight: FontWeight.w800,
                letterSpacing: horizontal ? 1.8 : 3)),
        SizedBox(height: horizontal ? 7 : 12),
        Text('Event Care',
            style: TextStyle(
                color: AppColors.coral,
                fontSize:
                    horizontal ? (compact ? 14 : 18) : (compact ? 20 : 27),
                letterSpacing: 1)),
      ],
    );
    final mark = CustomPaint(
        size: Size(
          horizontal ? (compact ? 46 : 62) : (compact ? 62 : 90),
          horizontal ? (compact ? 34 : 46) : (compact ? 44 : 64),
        ),
        painter: _ProwemMarkPainter());
    if (horizontal) {
      return Row(
          mainAxisSize: MainAxisSize.min,
          children: [mark, const SizedBox(width: 12), label]);
    }
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: [mark, SizedBox(height: compact ? 10 : 18), label]);
  }
}

class _ProwemMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          const LinearGradient(colors: [Color(0xFFFF8A3D), AppColors.coralDeep])
              .createShader(Offset.zero & size);
    final top = Path()
      ..moveTo(size.width * .18, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * .86, size.height * .38)
      ..lineTo(0, size.height * .38)
      ..close();
    final middle = Path()
      ..moveTo(size.width * .42, size.height * .25)
      ..lineTo(size.width * .82, size.height * .25)
      ..lineTo(size.width * .28, size.height)
      ..lineTo(size.width * .16, size.height)
      ..close();
    canvas.save();
    canvas.skew(-.13, 0);
    canvas.drawPath(top, paint);
    canvas.drawPath(middle, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
