import 'package:flutter/material.dart';

class ExpandableContainer extends StatelessWidget {
  final bool isExpanded;
  final Color borderColor;
  final Color backgroundColor;
  final Widget child;

  const ExpandableContainer({
    super.key,
    required this.isExpanded,
    required this.borderColor,
    required this.backgroundColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      // padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        padding: const EdgeInsets.all(10.0),
        child: child,
      ),
    );
  }
}
