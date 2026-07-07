import 'dart:io';

import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';

class CategoryPickerAdmin extends StatefulWidget {
  const CategoryPickerAdmin({super.key});

  @override
  _CategoryPickerAdminState createState() => _CategoryPickerAdminState();
}

class _CategoryPickerAdminState extends State<CategoryPickerAdmin> {
  Category? _selectedCategory;
  bool _isAddingCategory = false;
  final TextEditingController _newCategoryController = TextEditingController();

  late Future<List<Category>> categories;

  // 3. Create a dedicated method to refresh the data
  void _refreshCategories() {
    setState(() {
      categories = DatabaseHelper().getCategories();
    });
  }

  @override
  void initState() {
    super.initState();
    // 2. Initialize it ONCE when the widget enters the screen
    _refreshCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 100),
            child: Center(
              child: Text(
                'La catégorie selectionnée correspond au dossier dans lequel tous les prochains résultats seront enregistrés.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(height: 25),

          FutureBuilder<List<Category>>(
            future: categories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error loading categories');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No categories available');
              }

              final cats = snapshot.data!;
              // set default selection if none
              if (_selectedCategory == null && cats.isNotEmpty) {
                _selectedCategory = cats.first;
              }

              return DropdownButton<Category>(
                value: _selectedCategory,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                style: Theme.of(context).textTheme.titleLarge,
                dropdownColor: const Color.fromARGB(255, 0, 0, 0),
                items: cats.map((c) {
                  return DropdownMenuItem<Category>(
                    value: c,
                    child: Text(c.label),
                  );
                }).toList(),
                onChanged: (Category? newVal) {
                  setState(() {
                    _selectedCategory = newVal;
                  });
                },
              );
            },
          ),

          if (_isAddingCategory)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _newCategoryController,
                decoration: const InputDecoration(
                  labelText: 'New Category Label',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          SizedBox(height: 25),
          if (_isAddingCategory)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  stderr.writeln(
                    'Adding new category: ${_newCategoryController.text}',
                  );
                  DatabaseHelper().insertCategory(
                    Category(id: null, label: _newCategoryController.text),
                  );
                  _refreshCategories();
                  _isAddingCategory = false;
                  _newCategoryController.clear();
                });
              },
              child: Text('Valider'),
            ),
          SizedBox(height: 25),
          if (_isAddingCategory)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAddingCategory = false;
                  _newCategoryController.clear();
                });
              },
              child: Text('Annuler'),
            ),
          SizedBox(height: 25),
          if (!_isAddingCategory)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isAddingCategory = true;
                });
              },
              child: const Text('Ajouter une Category'),
            ),
          SizedBox(height: 25),
          if (_selectedCategory != null)
            ElevatedButton(
              onPressed: () {
                DatabaseHelper().getCategories().then(
                  (value) => {
                    for (var cat in value)
                      if (cat.label == _selectedCategory!.label)
                        {DatabaseHelper().deleteCategory(cat)},
                    setState(() {
                      _selectedCategory = null;
                      _refreshCategories();
                    }),
                  },
                );
              },
              child: const Text('Supprimer la catégorie selectionnée'),
            ),
        ],
      ),
    );
  }
}
