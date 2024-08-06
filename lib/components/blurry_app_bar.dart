import 'package:flutter/material.dart';
import 'dart:ui';

class BlurryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final double height;

  const BlurryAppBar({super.key, this.height = kToolbarHeight});

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          color: Colors.black.withOpacity(0.2),
          child: SafeArea(
            child: SizedBox(
              height: screenSize.height * 0.001,
              width: screenSize.width,
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
