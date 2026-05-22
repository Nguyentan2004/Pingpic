import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HistorySkeletonTile extends StatelessWidget {
  const HistorySkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
