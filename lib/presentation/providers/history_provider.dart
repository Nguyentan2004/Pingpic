import 'package:flutter/material.dart';
import '../../core/constants/dummy_data.dart';
import '../../data/repositories/photo_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final PhotoRepository _photoRepo = PhotoRepository();
  List<DummyHistoryPhoto> _history = [];
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<DummyHistoryPhoto> get history => _history;

  Future<void> fetchHistoryPhotos() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final newHistory = await _photoRepo.getHistoryPhotos();
      _history = newHistory;
    } catch (e) {
      // Xử lý lỗi tuỳ ý
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addNewMoment(DummyHistoryPhoto newMoment) {
    _history.insert(0, newMoment);
    notifyListeners();
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
}
