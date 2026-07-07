import 'package:flutter/foundation.dart';
import 'package:match_ta_formation_0/DataBase/link.dart' as lnk;

class CategoryProvider extends ChangeNotifier {
  lnk.Category? _selectedCategory;

  lnk.Category? get selectedCategory => _selectedCategory;

  void selectCategory(lnk.Category category) {
    _selectedCategory = category;
    notifyListeners(); // Tells listening widgets to rebuild
  }
}