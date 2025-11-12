import 'package:flutter/material.dart';
import 'dart:ui';

class FrostedGlassBox extends StatelessWidget {
  const FrostedGlassBox({
    Key? key,
    required this.theWidth,
    required this.theHeight,
    required this.theChild,
  }) : super(key: key);

  // Accept num so callers can pass int or double. We'll convert to double when using.
  final num theWidth;
  final num theHeight;
  final Widget theChild;

  @override
  Widget build(BuildContext context) {
    // Convert to double for Flutter APIs that require double
    final double w = theWidth.toDouble();
    final double h = theHeight.toDouble();

    return ClipRRect(
      borderRadius: BorderRadius.circular(30.0),
      child: Container(
        width: w,
        height: h,
        color: Colors.transparent,
        child: Stack(
          children: [
            // blur effect
            BackdropFilter(
              filter: ImageFilter.blur(
                // sigmaX and sigmaY expect double
                sigmaX: 4.0,
                sigmaY: 4.0,
              ),
              child: Container(),
            ),

            // gradient + border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.white.withOpacity(0.13)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),

            // content placed on top
            Center(child: theChild),
          ],
        ),
      ),
    );
  }
}
