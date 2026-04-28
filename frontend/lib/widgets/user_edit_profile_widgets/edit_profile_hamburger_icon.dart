import 'package:flutter/material.dart';

class EditProfileHamburgerIcon extends StatelessWidget {
  const EditProfileHamburgerIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 14,
            height: 2.5,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(2)),
          ),
          Container(
            width: 22,
            height: 2.5,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }
}