import 'package:flutter/foundation.dart';

class PhotoProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _feed = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get feed => _feed;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchFeed() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: Gọi PhotoRepository.getFeed()
      await Future.delayed(const Duration(seconds: 1));
      _feed = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPhoto(String imagePath, String caption) async {
    // TODO: Gọi PhotoRepository.sendPhoto()
    return false;
  }
}
