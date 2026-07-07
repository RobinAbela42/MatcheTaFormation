// import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/Pages/Admin/formation_admin_page.dart';
import 'package:match_ta_formation_0/Pages/Admin/category_picker_admin.dart';
import 'package:match_ta_formation_0/DataBase/link.dart' as lnk;
import 'package:match_ta_formation_0/Pages/Admin/situation_admin_page.dart';
import 'package:provider/provider.dart';

import '../../Pages/provider.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  void _initializeCategory(lnk.Category cat) {
    lnk.Category category = cat;

    // Update the provider without triggering a rebuild here (listen: false)
    Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).selectCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Page')),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Situations'),
                Tab(text: 'Formations'),
                Tab(text: 'Resultats'),
                Tab(text: 'Categories'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SituationAdminPage(),
                  FormationAdminPage(),
                  ResultAdminPage(),
                  CategoryPickerAdmin(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Situation
class SituationAdminPage extends StatefulWidget {
  const SituationAdminPage({super.key});

  @override
  State<SituationAdminPage> createState() => _SituationAdminPageState();
}

class _SituationAdminPageState extends State<SituationAdminPage> {
  final databaseHelper = lnk.DatabaseHelper();
  lnk.Situation? _selectedSituation;
  bool _isAddingSituation = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<lnk.Situation>>(
      future: databaseHelper.getSituations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No situations found.'));
        }

        if (_isAddingSituation) {
          return SituationAdd(
            onClose: () => setState(() {
              _isAddingSituation = false;
            }),
          );
        }

        if (_selectedSituation != null) {
          return SituationEdit(
            situation: _selectedSituation!,
            onClose: () => setState(() => _selectedSituation = null),
          );
        }

        final situations = snapshot.data!;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => {
                  setState(() {
                    _isAddingSituation = true;
                  }),
                },
                icon: const Icon(Icons.add),
                label: Text('Ajouter une situation'),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: situations.length,
                itemBuilder: (context, index) {
                  final s = situations[index];
                  return SituationCard(
                    title: s.description,
                    response1: (s.responses != null && s.responses!.isNotEmpty)
                        ? s.responses![0].description ?? 'No response 1'
                        : 'No response 1',
                    response2: (s.responses != null && s.responses!.length > 1)
                        ? s.responses![1].description ?? 'No response 2'
                        : 'No response 2',
                    onTap: () {
                      setState(() {
                        _selectedSituation = s;
                      });
                    },
                    onDelete: () async {
                      await lnk.DatabaseHelper().deleteSituation(s);
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class SituationCard extends StatelessWidget {
  final String title;
  final String response1;
  final String response2;
  final VoidCallback? onTap;
  final AsyncCallback? onDelete;

  const SituationCard({
    super.key,
    required this.title,
    required this.response1,
    required this.response2,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Response 1: $response1',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Response 2: $response2',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              ElevatedButton(onPressed: onDelete, child: Icon(Icons.delete)),
            ],
          ),
        ),
      ),
    );
  }
}

//Formations
class FormationAdminPage extends StatefulWidget {
  const FormationAdminPage({super.key});

  @override
  State<FormationAdminPage> createState() => _FormationAdminPageState();
}

class _FormationAdminPageState extends State<FormationAdminPage> {
  // Instantiate the helper once, or manage it via dependency injection/initState
  final databaseHelper = lnk.DatabaseHelper();
  lnk.Formation? _selectedFormation;
  bool _isAddingFormation = false;

  @override
  Widget build(BuildContext context) {
    if (_selectedFormation != null) {
      return FormationEdit(
        formation: _selectedFormation!,
        onClose: () => setState(() => _selectedFormation = null),
      );
    }

    if (_isAddingFormation) {
      return FormationAdd(
        onClose: () => setState(() => _isAddingFormation = false),
      );
    }

    return FutureBuilder<List<lnk.Formation>>(
      future: databaseHelper.getFormations(), // The async function
      builder: (context, snapshot) {
        // 1. Handle the loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Handle errors if the database call fails
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // 3. Handle the case where data is empty or missing
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No formations found.'));
        }

        // 4. Data is safely available here
        final formations = snapshot.data!;

        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isAddingFormation = true;
                        });
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter une formation'),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: formations.length,
                      itemBuilder: (context, index) {
                        final f = formations[index];
                        return FormationCard(
                          title: f.name,
                          subtitle: f.description,
                          onTap: () {
                            setState(() {
                              _selectedFormation = f;
                            });
                          },
                          onDelete: () async {
                            await lnk.DatabaseHelper().deleteFormation(f);
                            setState(() {});
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class FormationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final AsyncCallback? onDelete;

  const FormationCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(child: Text(title.substring(0, 1))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              ElevatedButton(onPressed: onDelete, child: Icon(Icons.delete)),
            ],
          ),
        ),
      ),
    );
  }
}

//Result
class ResultAdminPage extends StatefulWidget {
  const ResultAdminPage({super.key});

  @override
  State<ResultAdminPage> createState() => _ResultAdminPageState();
}

class _ResultAdminPageState extends State<ResultAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Resultats content'));
  }
}
