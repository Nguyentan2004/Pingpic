import 'dart:typed_data';

/// Dummy data models dùng cho UI tĩnh (chưa có API)

// ── Feed photo model ─────────────────────────────────────────────────────────
class DummyPhoto {
  final String id;
  final String imageUrl;
  final Uint8List? imageBytes; // Hỗ trợ hiển thị ảnh vừa upload (chưa có link)
  final String? userId; // ID của người gửi ảnh từ Firebase Auth/Firestore
  final String senderName;
  final String senderAvatar;
  final String timeAgo;
  final String? caption;
  final int reactionCount;
  final List<String> likes;
  final DateTime? createdAt;

  const DummyPhoto({
    required this.id,
    required this.imageUrl,
    this.imageBytes,
    this.userId,
    required this.senderName,
    required this.senderAvatar,
    required this.timeAgo,
    this.caption,
    this.reactionCount = 0,
    this.likes = const [],
    this.createdAt,
  });

  factory DummyPhoto.fromJson(Map<String, dynamic> json) {
    return DummyPhoto(
      id: json['id']?.toString() ?? 'img_${DateTime.now().millisecondsSinceEpoch}',
      imageUrl: json['imageUrl'] ?? 'https://picsum.photos/seed/${json['id']}/600/800',
      userId: json['userId']?.toString(),
      senderName: json['senderName'] ?? 'Unknown User',
      senderAvatar: json['senderAvatar'] ?? 'https://i.pravatar.cc/150?u=${json['senderName'] ?? 'unknown'}',
      timeAgo: json['timeAgo'] ?? 'Recently',
      caption: json['caption'],
      reactionCount: json['reactionCount'] ?? 0,
      likes: List<String>.from(json['likes'] ?? []),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }
}

// ── History photo model ───────────────────────────────────────────────────────
class DummyHistoryPhoto {
  final String id;
  final String imageUrl;
  final Uint8List? imageBytes; // Hỗ trợ hiển thị ảnh vừa upload
  final String sentAt;       // Chuỗi hiển thị (VD: "Today, 10:32 AM")
  final DateTime sentDate;   // DateTime thực để sort / group
  final String? caption;
  final int recipientCount;
  final int reactionCount;

  const DummyHistoryPhoto({
    required this.id,
    required this.imageUrl,
    this.imageBytes,
    required this.sentAt,
    required this.sentDate,
    this.caption,
    this.recipientCount = 5,
    this.reactionCount = 0,
  });
}

// ── All dummy data ────────────────────────────────────────────────────────────
class DummyData {
  // Feed ảnh từ bạn bè
  static const List<DummyPhoto> feed = [
    DummyPhoto(
      id: '1',
      imageUrl: 'https://picsum.photos/seed/locket1/600/700',
      senderName: 'Minh Khoa',
      senderAvatar: 'https://i.pravatar.cc/150?img=3',
      timeAgo: 'Just now',
      caption: 'Good morning! ☀️',
      reactionCount: 3,
    ),
    DummyPhoto(
      id: '2',
      imageUrl: 'https://picsum.photos/seed/locket2/600/700',
      senderName: 'Thu Hà',
      senderAvatar: 'https://i.pravatar.cc/150?img=5',
      timeAgo: '5 minutes ago',
      caption: 'Cà phê sáng thật ngon 🫶',
      reactionCount: 7,
    ),
    DummyPhoto(
      id: '3',
      imageUrl: 'https://picsum.photos/seed/locket3/600/700',
      senderName: 'Bảo Trân',
      senderAvatar: 'https://i.pravatar.cc/150?img=9',
      timeAgo: '22 minutes ago',
      caption: null,
      reactionCount: 12,
    ),
    DummyPhoto(
      id: '4',
      imageUrl: 'https://picsum.photos/seed/locket4/600/700',
      senderName: 'Đức Anh',
      senderAvatar: 'https://i.pravatar.cc/150?img=12',
      timeAgo: '1 hour ago',
      caption: 'View from the office 🏙️',
      reactionCount: 5,
    ),
    DummyPhoto(
      id: '5',
      imageUrl: 'https://picsum.photos/seed/locket5/600/700',
      senderName: 'Quỳnh Như',
      senderAvatar: 'https://i.pravatar.cc/150?img=16',
      timeAgo: '2 hours ago',
      caption: 'Lunch with the crew! 🍜',
      reactionCount: 18,
    ),
  ];

  // Danh sách bạn bè
  static const List<Map<String, String>> friends = [
    {'name': 'Minh Khoa', 'avatar': 'https://i.pravatar.cc/150?img=3', 'status': 'online'},
    {'name': 'Thu Hà',    'avatar': 'https://i.pravatar.cc/150?img=5', 'status': 'online'},
    {'name': 'Bảo Trân',  'avatar': 'https://i.pravatar.cc/150?img=9', 'status': 'offline'},
    {'name': 'Đức Anh',   'avatar': 'https://i.pravatar.cc/150?img=12', 'status': 'online'},
    {'name': 'Quỳnh Như', 'avatar': 'https://i.pravatar.cc/150?img=16', 'status': 'offline'},
  ];

  // Lịch sử 20 ảnh người dùng đã gửi
  static final List<DummyHistoryPhoto> history = [
    DummyHistoryPhoto(
      id: 'h1',
      imageUrl: 'https://picsum.photos/seed/hist1/400/500',
      sentAt: 'Today, 10:32 AM',
      sentDate: DateTime.now().subtract(const Duration(hours: 1)),
      caption: 'Good morning! ☀️',
      recipientCount: 5,
      reactionCount: 8,
    ),
    DummyHistoryPhoto(
      id: 'h2',
      imageUrl: 'https://picsum.photos/seed/hist2/400/500',
      sentAt: 'Today, 08:15 AM',
      sentDate: DateTime.now().subtract(const Duration(hours: 3)),
      caption: null,
      recipientCount: 5,
      reactionCount: 3,
    ),
    DummyHistoryPhoto(
      id: 'h3',
      imageUrl: 'https://picsum.photos/seed/hist3/400/500',
      sentAt: 'Yesterday, 09:44 PM',
      sentDate: DateTime.now().subtract(const Duration(hours: 14)),
      caption: 'Night vibes 🌙',
      recipientCount: 4,
      reactionCount: 12,
    ),
    DummyHistoryPhoto(
      id: 'h4',
      imageUrl: 'https://picsum.photos/seed/hist4/400/500',
      sentAt: 'Yesterday, 06:20 PM',
      sentDate: DateTime.now().subtract(const Duration(hours: 18)),
      caption: 'Dinner is served 🍜',
      recipientCount: 5,
      reactionCount: 7,
    ),
    DummyHistoryPhoto(
      id: 'h5',
      imageUrl: 'https://picsum.photos/seed/hist5/400/500',
      sentAt: 'Yesterday, 01:05 PM',
      sentDate: DateTime.now().subtract(const Duration(hours: 23)),
      caption: null,
      recipientCount: 3,
      reactionCount: 2,
    ),
    DummyHistoryPhoto(
      id: 'h6',
      imageUrl: 'https://picsum.photos/seed/hist6/400/500',
      sentAt: 'May 9, 11:30 AM',
      sentDate: DateTime.now().subtract(const Duration(days: 2)),
      caption: 'Weekend mood 🏖️',
      recipientCount: 5,
      reactionCount: 18,
    ),
    DummyHistoryPhoto(
      id: 'h7',
      imageUrl: 'https://picsum.photos/seed/hist7/400/500',
      sentAt: 'May 9, 07:55 AM',
      sentDate: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
      caption: null,
      recipientCount: 5,
      reactionCount: 0,
    ),
    DummyHistoryPhoto(
      id: 'h8',
      imageUrl: 'https://picsum.photos/seed/hist8/400/500',
      sentAt: 'May 8, 08:00 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 3)),
      caption: 'Movie night 🎬',
      recipientCount: 2,
      reactionCount: 5,
    ),
    DummyHistoryPhoto(
      id: 'h9',
      imageUrl: 'https://picsum.photos/seed/hist9/400/500',
      sentAt: 'May 8, 12:20 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 3, hours: 8)),
      caption: 'Lunch break ☕',
      recipientCount: 5,
      reactionCount: 9,
    ),
    DummyHistoryPhoto(
      id: 'h10',
      imageUrl: 'https://picsum.photos/seed/hist10/400/500',
      sentAt: 'May 7, 06:45 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 4)),
      caption: 'Golden hour 🌅',
      recipientCount: 5,
      reactionCount: 22,
    ),
    DummyHistoryPhoto(
      id: 'h11',
      imageUrl: 'https://picsum.photos/seed/hist11/400/500',
      sentAt: 'May 7, 10:10 AM',
      sentDate: DateTime.now().subtract(const Duration(days: 4, hours: 9)),
      caption: null,
      recipientCount: 4,
      reactionCount: 4,
    ),
    DummyHistoryPhoto(
      id: 'h12',
      imageUrl: 'https://picsum.photos/seed/hist12/400/500',
      sentAt: 'May 6, 03:30 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 5)),
      caption: 'Afternoon walk 🌿',
      recipientCount: 5,
      reactionCount: 11,
    ),
    DummyHistoryPhoto(
      id: 'h13',
      imageUrl: 'https://picsum.photos/seed/hist13/400/500',
      sentAt: 'May 6, 08:00 AM',
      sentDate: DateTime.now().subtract(const Duration(days: 5, hours: 7)),
      caption: 'Morning run 🏃',
      recipientCount: 5,
      reactionCount: 6,
    ),
    DummyHistoryPhoto(
      id: 'h14',
      imageUrl: 'https://picsum.photos/seed/hist14/400/500',
      sentAt: 'May 5, 09:15 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 6)),
      caption: null,
      recipientCount: 3,
      reactionCount: 1,
    ),
    DummyHistoryPhoto(
      id: 'h15',
      imageUrl: 'https://picsum.photos/seed/hist15/400/500',
      sentAt: 'May 4, 05:00 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 7)),
      caption: 'Rooftop views 🌃',
      recipientCount: 5,
      reactionCount: 30,
    ),
    DummyHistoryPhoto(
      id: 'h16',
      imageUrl: 'https://picsum.photos/seed/hist16/400/500',
      sentAt: 'May 3, 02:00 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 8)),
      caption: null,
      recipientCount: 2,
      reactionCount: 0,
    ),
    DummyHistoryPhoto(
      id: 'h17',
      imageUrl: 'https://picsum.photos/seed/hist17/400/500',
      sentAt: 'May 2, 11:45 AM',
      sentDate: DateTime.now().subtract(const Duration(days: 9)),
      caption: 'Study session 📚',
      recipientCount: 5,
      reactionCount: 3,
    ),
    DummyHistoryPhoto(
      id: 'h18',
      imageUrl: 'https://picsum.photos/seed/hist18/400/500',
      sentAt: 'May 1, 07:20 AM',
      sentDate: DateTime.now().subtract(const Duration(days: 10)),
      caption: 'May Day! 🎉',
      recipientCount: 5,
      reactionCount: 15,
    ),
    DummyHistoryPhoto(
      id: 'h19',
      imageUrl: 'https://picsum.photos/seed/hist19/400/500',
      sentAt: 'Apr 30, 08:30 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 11)),
      caption: null,
      recipientCount: 4,
      reactionCount: 7,
    ),
    DummyHistoryPhoto(
      id: 'h20',
      imageUrl: 'https://picsum.photos/seed/hist20/400/500',
      sentAt: 'Apr 29, 04:00 PM',
      sentDate: DateTime.now().subtract(const Duration(days: 12)),
      caption: 'First photo sent! 🎊',
      recipientCount: 5,
      reactionCount: 25,
    ),
  ];
}
