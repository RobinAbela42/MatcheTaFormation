// import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/Pages/Admin/formation_admin_page.dart';
import 'package:match_ta_formation_0/Pages/Admin/category_picker_admin.dart';
import 'package:match_ta_formation_0/DataBase/link.dart' as lnk;
import 'package:match_ta_formation_0/Pages/Admin/situation_admin_page.dart';
import 'package:match_ta_formation_0/Pages/Admin/display_admin_page.dart';

/// Page d'accueil de l'espace administrateur, accessible après
/// authentification réussie depuis [AdminLogin].
///
/// Organise l'administration de l'application en 4 onglets via un
/// [DefaultTabController] :
/// - **Situations** : [SituationAdminPage], gestion des situations
///   présentées à l'utilisateur dans le parcours de swipe.
/// - **Formations** : [FormationAdminPage], gestion des formations
///   proposées en résultat du matching.
/// - **Resultats** : [ResultAdminPage], consultation des résultats de
///   session enregistrés (voir `insertResult` dans [ResultDisplay]).
/// - **Categories** : [CategoryPickerAdmin], gestion des catégories
///   (voir [CategoryProvider]).
///
/// Chaque onglet est un widget autonome et indépendant : cette page ne
/// fait qu'assembler la structure de navigation (barre d'onglets +
/// contenu correspondant), sans logique métier propre.

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  // ignore: unused_element

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Page')),
      body: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              unselectedLabelColor: Color(0xFF1C2AAF),
              tabs: [
                Tab(text: 'Situations'),
                Tab(text: 'Formations'),
                Tab(text: 'Resultats'),
                Tab(text: 'Categories'),
                Tab(text: 'Display'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SituationAdminPage(),
                  FormationAdminPage(),
                  ResultAdminPage(),
                  CategoryPickerAdmin(),
                  DisplayAdminPage(),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onglet d'administration permettant de lister, créer, modifier et
/// supprimer les [lnk.Situation] présentées aux utilisateurs dans le
/// parcours de swipe (voir [UserPage] / [SwipeCard]).
///
/// Trois modes d'affichage s'excluent mutuellement, pilotés par l'état
/// local (`_isAddingSituation`, `_selectedSituation`) :
/// - **Liste** (mode par défaut) : charge l'ensemble des situations via
///   `databaseHelper.getSituations()` et les affiche sous forme de
///   [SituationCard], chacune résumant la description de la situation et
///   ses deux premières réponses. Un tap sur une carte bascule en mode
///   édition ; l'icône de suppression appelle
///   `DatabaseHelper().deleteSituation(s)` puis force un rafraîchissement
///   de la liste.
/// - **Ajout** (`_isAddingSituation == true`) : affiche [SituationAdd],
///   un formulaire de création dédié. La fermeture du formulaire
///   (`onClose`) repasse en mode liste.
/// - **Édition** (`_selectedSituation != null`) : affiche [SituationEdit]
///   pour la situation sélectionnée. La fermeture (`onClose`) repasse en
///   mode liste.

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
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
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

              ElevatedButton(
                onPressed: onDelete,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                ),
                child: Icon(Icons.delete, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte réutilisable et sans état affichant le résumé d'une
/// [lnk.Situation] dans les écrans d'administration (voir
/// [SituationAdminPage]).
///
/// Affiche le [title] (description de la situation) ainsi que ses deux
/// premières réponses possibles ([response1] et [response2]), avec un
/// bouton de suppression (icône poubelle) en fin de ligne.
///
/// Deux interactions sont exposées, toutes deux optionnelles :
/// - [onTap] : déclenché au tap sur l'ensemble de la carte (via
///   [InkWell]), typiquement utilisé pour ouvrir l'édition de la
///   situation correspondante.
/// - [onDelete] : déclenché uniquement par le bouton dédié, typiquement
///   utilisé pour supprimer la situation en base de données. Typé
///   [AsyncCallback] afin de permettre un traitement asynchrone (ex.
///   attendre la fin de la suppression avant de rafraîchir la liste
///   parente).
///
/// Ce widget est purement présentationnel ([StatelessWidget]) : il ne
/// contient aucune logique métier ni appel direct à la base de données,
/// toute la logique étant déléguée au widget parent via les callbacks.
/// /// Points d'attention pour les développeurs :
/// - Le bouton de suppression est un simple [ElevatedButton] contenant
///   une icône, sans confirmation ni retour visuel de chargement pendant
///   l'exécution de [onDelete] : si la suppression prend du temps
///   (latence réseau/DB), l'utilisateur ne reçoit aucun indice qu'une
///   action est en cours et pourrait cliquer plusieurs fois. À envisager
///   un état de chargement local ou une désactivation temporaire du
///   bouton.

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

/// Carte réutilisable et sans état affichant le résumé d'une formation.
///
/// Affiche le [title] et le [subtitle] de la formation, accompagnés d'un
/// [CircleAvatar] généré à partir de la première lettre du titre, ainsi
/// qu'un bouton de suppression (icône poubelle rouge) en fin de ligne.
///
/// Deux interactions sont exposées, toutes deux optionnelles :
/// - [onTap] : déclenché au tap sur l'ensemble de la carte (via
///   [InkWell]), typiquement utilisé pour naviguer vers l'écran de détail
///   ou d'édition de la formation correspondante.
/// - [onDelete] : déclenché uniquement par le bouton dédié, typiquement
///   utilisé pour supprimer la formation. Typé [AsyncCallback] afin de
///   permettre un traitement asynchrone (ex. attendre la fin de la requête
///   réseau avant de mettre à jour l'interface).
///
/// Ce widget est purement présentationnel ([StatelessWidget]) : il ne
/// contient aucune logique métier ni appel direct à la base de données,
/// toute la logique étant déléguée au widget parent via les callbacks.
///
/// Points d'attention pour les développeurs :
/// - Le bouton de suppression est un simple [ElevatedButton] sans étape de
///   confirmation préalable ni retour visuel de chargement pendant
///   l'exécution de [onDelete]. Si la suppression prend du temps,
///   l'utilisateur ne reçoit aucun indice visuel et pourrait cliquer
///   plusieurs fois.

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
              CircleAvatar(child: Text(title.substring(0, 1), style: Theme.of(context).textTheme.titleLarge,)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onDelete,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.white),
                ),
                child: Icon(Icons.delete, color: Colors.red),
              ),
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
  final databaseHelper = lnk.DatabaseHelper();
  bool _isLoading = true;
  List<lnk.Category> _categories = [];
  List<lnk.Result> _allResults = [];

  // Selected category ID (null represents "All Categories")
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchDatabaseData();
  }

  Future<void> _fetchDatabaseData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch results using your getResult() method
      final results = await databaseHelper.getResult(); // Your SQLite query method

      // 2. Extract unique categories from fetched results
      final Map<int, lnk.Category> categoryMap = {};
      for (final res in results) {
        if (res.category != null && res.category!.id != null) {
          categoryMap[res.category!.id!] = res.category!;
        }
      }

      setState(() {
        _allResults = results;
        _categories = categoryMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  // Filter results based on the selected dropdown value
  List<lnk.Result> get _filteredResults {
    if (_selectedCategoryId == null) {
      return _allResults; // Show all results if no filter selected
    }
    return _allResults
        .where((result) => result.category?.id == _selectedCategoryId)
        .toList();
  }
@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats par catégorie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDatabaseData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 1. DROPDOWN CATEGORY FILTER
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: 'Filtrer par catégorie',
                      prefixIcon: const Icon(Icons.category),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      // Option for showing all results
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Toute les catégories'),
                      ),
                      // Dynamic options based on database categories
                      ..._categories.map((category) {
                        return DropdownMenuItem<int?>(
                          value: category.id,
                          child: Text('${category.id} : ${category.label}'),
                        );
                      }),
                    ],
                    onChanged: (selectedId) {
                      setState(() {
                        _selectedCategoryId = selectedId;
                      });
                    },
                  ),
                ),

                const Divider(height: 1),

                // 2. RESULTS LIST
                Expanded(
                  child: _filteredResults.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun resultat pour cette catégorie.',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filteredResults.length,
                          itemBuilder: (context, index) {
                            final result = _filteredResults[index];
                            return _ResultCard(result: result);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}


class _ResultCard extends StatelessWidget {
  final lnk.Result result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final formattedDate = result.time != null
        ? "${result.time!.day}/${result.time!.month}/${result.time!.year} at ${result.time!.hour}:${result.time!.minute.toString().padLeft(2, '0')}"
        : "No date recorded";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Result ID & Category Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Résultat #${result.id ?? "N/A"}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (result.category != null)
                  Chip(
                    label: Text(
                      result.category!.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Date & Time
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),

            // Formations details (if present)
            if (result.formations != null && result.formations!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Formations matchée${result.formations!.length > 1 ? 's' : ''} :',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: result.formations!.entries.map((entry) {
                  final formation = entry.key;
                  final weight = entry.value;
                  return Chip(
                    avatar: CircleAvatar(
                      child: Text(
                        '$weight',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    label: Text('${formation.name}'),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}