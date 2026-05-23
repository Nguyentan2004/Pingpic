import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/dummy_data.dart';
import '../../../core/utils/time_formatter.dart';
import '../../widgets/photo_card.dart';
import 'package:pingpic/l10n/app_localizations.dart';

class MomentViewerPage extends StatefulWidget {
  final String userId;
  final String senderName;
  final String senderAvatar;
  final int initialIndex;
  final String? initialMomentId;

  const MomentViewerPage({
    super.key,
    required this.userId,
    required this.senderName,
    required this.senderAvatar,
    required this.initialIndex,
    this.initialMomentId,
  });

  @override
  State<MomentViewerPage> createState() => _MomentViewerPageState();
}

class _MomentViewerPageState extends State<MomentViewerPage> {
  PageController? _pageController;
  bool _isPageAnimating = false;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isResponsive = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          AppLocalizations.of(context)!.profileUserMomentsTitle(widget.senderName),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('moments')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.generalError(snapshot.error.toString()),
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                AppLocalizations.of(context)!.profileNoMoments,
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }

          // Map documents to DummyPhoto objects
          final list = docs.map((doc) {
            final data = doc.data();
            final Timestamp? timestamp = data['createdAt'];
            final DateTime sentDate = timestamp?.toDate() ?? DateTime.now();
            final l10n = AppLocalizations.of(context);

            return _PhotoWithDate(
              DummyPhoto(
                id: doc.id,
                imageUrl: data['imageUrl'] ?? '',
                imageBytes: null,
                userId: widget.userId,
                senderName: widget.senderName,
                senderAvatar: widget.senderAvatar,
                timeAgo: formatMomentTime(sentDate, l10n: l10n),
                caption: data['caption'],
                reactionCount: data['reactionCount'] ?? 0,
                likes: List<String>.from(data['likes'] ?? []),
                createdAt: sentDate,
              ),
              sentDate,
            );
          }).toList();

          // Sort in descending order (newest first, oldest last)
          list.sort((a, b) => b.sentDate.compareTo(a.sentDate));

          // Initialize the PageController on first data load
          if (_pageController == null) {
            int targetPage = -1;
            if (widget.initialMomentId != null) {
              targetPage = list.indexWhere((item) => item.photo.id == widget.initialMomentId);
            }
            if (targetPage == -1) {
              targetPage = widget.initialIndex.clamp(0, list.length - 1);
            }
            _pageController = PageController(initialPage: targetPage);
          }

          return Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                final dy = pointerSignal.scrollDelta.dy;
                if (dy != 0 && !_isPageAnimating) {
                  final targetPage = dy > 0 
                      ? ((_pageController?.page ?? 0).round() + 1) 
                      : ((_pageController?.page ?? 0).round() - 1);
                  
                  if (targetPage >= 0 && targetPage < list.length) {
                    _isPageAnimating = true;
                    _pageController?.animateToPage(
                      targetPage,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    ).then((_) {
                      _isPageAnimating = false;
                    });
                  }
                }
              }
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: kIsWeb 
                  ? const NeverScrollableScrollPhysics() 
                  : const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final photo = list[index].photo;
                final card = PhotoCard(
                  photo: photo,
                  index: index,
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isResponsive
                      ? Center(
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: card,
                          ),
                        )
                      : card,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PhotoWithDate {
  final DummyPhoto photo;
  final DateTime sentDate;

  _PhotoWithDate(this.photo, this.sentDate);
}
