import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/dummy_data.dart';
import '../../data/repositories/photo_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final PhotoRepository _photoRepo = PhotoRepository();
  List<DummyHistoryPhoto> _history = [];
  StreamSubscription<List<DummyHistoryPhoto>>? _historySubscription;
  String? _listenedUserId;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DummyHistoryPhoto> get history => _history;

  Future<void> fetchHistoryPhotos() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;
    
    if (_listenedUserId == currentUserId && _historySubscription != null) {
      return;
    }
    
    _listenedUserId = currentUserId;
    _historySubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _historySubscription = _photoRepo.getHistoryPhotosStream(currentUserId).listen(
      (newHistory) {
        _history = newHistory;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        notifyListeners();
      }
    );
  }

  void addNewMoment(DummyHistoryPhoto newMoment) {
    if (!_history.any((m) => m.id == newMoment.id)) {
      _history.insert(0, newMoment);
      notifyListeners();
    }
  }

  Future<void> deleteMoment(String id) async {
    try {
      await _photoRepo.deletePhoto(id);
      _history.removeWhere((moment) => moment.id == id);
      notifyListeners();
    } catch (e) {
      // ErrorInterceptor sẽ bắt các lỗi API, nhưng có thể cần throw để UI (Dialog) tắt trạng thái loading.
      rethrow;
    }
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }
}
