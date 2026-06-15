import 'package:flutter/material.dart';

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

class _FormationAdminPageState extends State<FormationAdminPage> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Response Types Content'));
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



