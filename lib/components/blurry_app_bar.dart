import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ctp/components/custom_back_button.dart';

class BlurryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;

  const BlurryAppBar({super.key, this.leading});

  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    final canPop = Navigator.of(context).canPop();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.1),
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
                leading: leading ??
                    (canPop
                        ? Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: () =>
                                        Navigator.of(context).maybePop(),
                                    child:
                                        const Center(child: CustomBackButton()),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null),
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
