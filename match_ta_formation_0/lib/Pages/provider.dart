import 'package:flutter/foundation.dart';
import 'package:match_ta_formation_0/DataBase/link.dart' as lnk;

/// Fournisseur d'état ([ChangeNotifier]) exposant la [lnk.Category]
/// actuellement sélectionnée par l'utilisateur (ex. secondaire/tertiaire,
/// ou autre catégorie de formation selon le contexte métier).
///
/// Destiné à être exposé via un `ChangeNotifierProvider` (package
/// `provider`) en haut de l'arbre de widgets, puis consommé par les écrans
/// ayant besoin de connaître ou de faire évoluer la catégorie active
/// (ex. [ResultDisplay], qui lit [selectedCategory] via
/// `Provider.of<CategoryProvider>(context, listen: false)` au moment
/// d'enregistrer un résultat en base).
///
/// Toute modification via [selectCategory] déclenche [notifyListeners],
/// entraînant la reconstruction des widgets qui écoutent ce provider
/// (`context.watch<CategoryProvider>()` ou équivalent).

class CategoryProvider extends ChangeNotifier {
  lnk.Category? _selectedCategory;

  lnk.Category? get selectedCategory => _selectedCategory;

  void selectCategory(lnk.Category category) {
    _selectedCategory = category;
    notifyListeners(); // Tells listening widgets to rebuild
  }
}