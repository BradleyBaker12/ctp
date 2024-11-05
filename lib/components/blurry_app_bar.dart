import 'package:flutter/material.dart';
import 'dart:ui';

class BlurryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;

  const BlurryAppBar({super.key, this.leading});

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            border: const Border(
              bottom: BorderSide(
                color: Color(0xFFFF4E00),
                width: 2.0, // Adjust the width of the border here
              ),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: screenSize.height * 0.001,
              width: screenSize.width,
              child: AppBar(
                leading: leading,
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
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
