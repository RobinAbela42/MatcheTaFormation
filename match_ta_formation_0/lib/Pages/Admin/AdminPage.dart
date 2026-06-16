import 'package:flutter/material.dart';
import 'package:match_ta_formation_0/DataBase/link.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Situations'),
                Tab(text: 'Formations'),
                Tab(text: 'Resultats'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SituationAdminPage(),
                  FormationAdminPage(),
                  ResultAdminPage(),
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
  const SituationAdminPage({Key? key}) : super(key: key);

  @override
  State<SituationAdminPage> createState() => _SituationAdminPageState();
}

class _SituationAdminPageState extends State<SituationAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Situations Content'));
  }
}




//Formations
class FormationAdminPage extends StatefulWidget {
  const FormationAdminPage({Key? key}) : super(key: key);

  @override
  State<FormationAdminPage> createState() => _FormationAdminPageState();
}

// class _FormationAdminPageState extends State<FormationAdminPage> {
//   @override
//   Widget build(BuildContext context) {
//     final databaseHelper = DatabaseHelper(); // Fetch formations from the database
//     final formations = databaseHelper.getFormations(); 

//     return ListView.builder(
//       padding: const EdgeInsets.all(12),
//       itemCount: formations.length,
//       itemBuilder: (context, index) {
//         final f = formations[index];
//         return FormationCard(
//           title: f['title']!,
//           subtitle: f['subtitle']!,
//           onTap: () {
//             // handle tap -- for now show simple snackbar
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(content: Text('Tapped ${f['title']}')),
//             );
//           },
//         );
//       },
//     );
//   }
// }

class _FormationAdminPageState extends State<FormationAdminPage> {
  // Instantiate the helper once, or manage it via dependency injection/initState
  final databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Formation>>(
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

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: formations.length,
          itemBuilder: (context, index) {
            final f = formations[index];
            return FormationCard(
              title: f.name,
              subtitle: f.description,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped ${f.name}')),
                );
              },
            );
          },
        );
      },
    );
  }
}

class FormationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const FormationCard({super.key, required this.title, required this.subtitle, this.onTap});

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
                    Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

//Result
class ResultAdminPage extends StatefulWidget {
  const ResultAdminPage({Key? key}) : super(key: key);

  @override
  State<ResultAdminPage> createState() => _ResultAdminPageState();
}

class _ResultAdminPageState extends State<ResultAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Responses Content'));
  }
}



