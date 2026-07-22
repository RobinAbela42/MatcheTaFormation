/// link.dart is the main file to  link the database to the app.
library;

import 'dart:async';

// import 'package:flutter/foundation.dart';
// import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Situation {
  final int? id;
  final List<Response>? responses;
  final String description;

  const Situation({
    required this.id,
    this.responses,
    required this.description,
  });

  Map<String, Object?> toMap() {
    return {'IdSituation': id, 'Description': description};
  }

  @override
  String toString() {
    return 'Situation(id: $id, description: $description, responses: $responses)';
  }
}

class Response {
  final int? id;
  final Map<Formation, int>? formations;
  final ResponseType type;
  final String? description;

  const Response({
    this.id,
    this.formations,
    this.description,
    required this.type,
  });

  Map<String, Object?> toMap() {
    return {
      'Description': description,
      'IdResponseType':
          type.id, // Foreign Key relation resolved from the object
    };
  }

  @override
  String toString() {
    return 'Response(id: $id, description: $description, type: $type, formations: $formations)';
  }
}

class ResponseType {
  final int id;
  final String label;

  const ResponseType({required this.id, required this.label});

  Map<String, Object?> toMap() {
    return {'IdResponseType': id, 'Label': label};
  }

  @override
  String toString() {
    return 'ResponseType(id: $id, label: $label)';
  }
}

class Formation {
  final int? id;
  final String name;
  final String description;
  final List<Level> levels;

  const Formation({
    this.id,
    required this.name,
    required this.description,
    required this.levels,
  });

  Map<String, Object?> toMap() {
    return {'IdFormation': id, 'Name': name, 'Description': description};
  }

  @override
  String toString() {
    return 'Formation(id: $id, name: $name, description: $description, levels: $levels)';
  }

  @override
  bool operator ==(Object other) => other is Formation && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class Result {
  final int? id;
  final Map<Formation, int>? formations;
  final DateTime? time;
  final Category? category;

  const Result({
    required this.id,
    required this.formations,
    required this.time,
    required this.category,
  });

  Map<String, Object?> toMap() {
    return {
      'IdResult': id,
      'Time': time
          ?.toIso8601String(), // Formatted safely for SQL text/datetime storage
      'IdCategory':
          category?.id, // Foreign Key relation resolved from the object
    };
  }

  @override
  String toString() {
    return 'Result(id: $id, time: $time, category: $category, formations: $formations)';
  }
}

class Admin {
  final int id;
  final String login;
  final String hash;

  const Admin({required this.id, required this.login, required this.hash});

  Map<String, Object?> toMap() {
    return {
      'IdAdmin': id,
      'Login': login,
      'Hash': hash, // Mapped to match your database schema column
    };
  }

  @override
  String toString() {
    return 'Admin(id: $id, login: $login, hash: $hash)';
  }
}

class Category {
  final int? id;
  final String label;

  const Category({required this.id, required this.label});

  Map<String, Object?> toMap() {
    return {'IdCategory': id, 'Label': label};
  }

  @override
  String toString() {
    return 'Category(id: $id, label: $label)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class Level {
  final int id;
  final String label;

  const Level({required this.id, required this.label});

  Map<String, Object?> toMap() {
    return {'IdLevel': id, 'Label': label};
  }

  @override
  String toString() {
    return 'Level(id: $id, label: $label)';
  }

  @override
  bool operator ==(Object other) => other is Level && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// void main() async {
//   // Avoid errors caused by flutter upgrade.
//   // Importing 'package:flutter/widgets.dart' is required.
//   WidgetsFlutterBinding.ensureInitialized();
//   // Open the database and store the reference.
//   // Initialize sqflite FFI on desktop platforms before opening the DB.

//   final databasePath = join(await getDatabasesPath(), 'data.db');
//   final database = openDatabase(databasePath);

// }

void main() {
  // 2. Ensure binding is initialized

  // Your main App widget
}

class DatabaseHelper {
  static Future<Database> initDb() async {
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, 'data.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        String creationScript = '''
DROP TABLE IF EXISTS Describe;
DROP TABLE IF EXISTS FormationResult;
DROP TABLE IF EXISTS ResponseFormation;
DROP TABLE IF EXISTS Result;
DROP TABLE IF EXISTS Response;
DROP TABLE IF EXISTS Formation;
DROP TABLE IF EXISTS Level;
DROP TABLE IF EXISTS Category;
DROP TABLE IF EXISTS ResponseType;
DROP TABLE IF EXISTS Situation;
DROP TABLE IF EXISTS Admin;


CREATE TABLE Admin (
    IdAdmin INTEGER PRIMARY KEY AUTOINCREMENT,
    Login VARCHAR(255) NOT NULL,
    Hash VARCHAR(255) NOT NULL
);

CREATE TABLE Situation (
    IdSituation INTEGER PRIMARY KEY AUTOINCREMENT,
    Description TEXT
);

CREATE TABLE ResponseType (
    IdResponseType INTEGER PRIMARY KEY AUTOINCREMENT,
    Label VARCHAR(255) NOT NULL
);

CREATE TABLE Category (
    IdCategory INTEGER PRIMARY KEY AUTOINCREMENT,
    Label VARCHAR(255) NOT NULL
);

CREATE TABLE Level (
    IdLevel INTEGER PRIMARY KEY AUTOINCREMENT,
    Label VARCHAR(255) NOT NULL
);

CREATE TABLE Formation (
    IdFormation INTEGER PRIMARY KEY AUTOINCREMENT,
    Name VARCHAR(255) NOT NULL,
    Description TEXT
);

CREATE TABLE Response (
    IdResponse INTEGER PRIMARY KEY AUTOINCREMENT,
    Description TEXT,
    IdSituation INTEGER NOT NULL,
    IdResponseType INTEGER NOT NULL,
    FOREIGN KEY (IdSituation) REFERENCES Situation(IdSituation) ON DELETE CASCADE, 
    FOREIGN KEY (IdResponseType) REFERENCES ResponseType(IdResponseType) ON DELETE RESTRICT
);

CREATE TABLE Result (
    IdResult INTEGER PRIMARY KEY AUTOINCREMENT,
    Time TIME NOT NULL,
    Date DATE NOT NULL,
    IdCategory INTEGER NOT NULL,
    FOREIGN KEY (IdCategory) REFERENCES Category(IdCategory) ON DELETE RESTRICT
);

CREATE TABLE ResponseFormation (
    IdResponse INTEGER,
    IdFormation INTEGER,
    Weight INTEGER NOT NULL,
    PRIMARY KEY (IdResponse, IdFormation),
    FOREIGN KEY (IdResponse) REFERENCES Response(IdResponse) ON DELETE CASCADE,
    FOREIGN KEY (IdFormation) REFERENCES Formation(IdFormation) ON DELETE CASCADE
);

CREATE TABLE FormationResult (
    IdResult INTEGER,
    IdFormation INTEGER,
    ResultWeight INTEGER NOT NULL,
    PRIMARY KEY (IdResult, IdFormation),
    FOREIGN KEY (IdResult) REFERENCES Result(IdResult) ON DELETE CASCADE,
    FOREIGN KEY (IdFormation) REFERENCES Formation(IdFormation) ON DELETE CASCADE
);

CREATE TABLE Describe (
    IdFormation INTEGER,
    IdLevel INTEGER,
    PRIMARY KEY (IdFormation, IdLevel),
    FOREIGN KEY (IdFormation) REFERENCES Formation(IdFormation) ON DELETE CASCADE,
    FOREIGN KEY (IdLevel) REFERENCES Level(IdLevel) ON DELETE CASCADE
);
        ''';

        String insertScriptBase = '''
INSERT INTO Admin (Login, Hash) 
VALUES ('admin', 'matche'),
('qwe', 'qwe');

INSERT INTO ResponseType (Label) VALUES
('Gauche'),
('Droite');

INSERT INTO Level (IdLevel, Label) VALUES 
(1, 'Secondaire'),
(2, 'Tertiaire');
        ''';

        //PlayTest written by chatgpt
        String insertScriptPlaytest = '''
INSERT INTO Formation (IdFormation, Name, Description) VALUES 
(1, 'PA', 'Procrastination Avancée'),
(2, 'CC101', 'Culture Café 101'),
(3, 'PP', 'Productivité en Pyjama'),
(4, 'ISP', 'Initiation au Soupir Professionnel'),
(5, 'AER', 'L''Art d''Éviter les Réunions'),
(6, 'SEAS', 'Sorcellerie Excel & Arts Sombres'),
(7, 'HTS', 'Hochements de Tête Stratégiques'),
(8, 'BJE', 'Bingo du Jargon d''Entreprise');

INSERT INTO Situation (IdSituation, Description) VALUES 
(1, 'Un client est furieux à cause d''un retard de livraison.'),
(2, 'La machine à café principale tombe en panne.'),
(3, 'Vous recevez une invitation Outlook pour une réunion un vendredi à 16h55.'),
(4, 'Le Wi-Fi se coupe pile au moment de lancer une présentation cruciale.'),
(5, 'Quelqu''un a laissé un plat de poisson très odorant dans le micro-ondes commun.'),
(6, 'Un e-mail urgent du PDG arrive avec la mention "Action Requise Immédiate".'),
(7, 'Vous répondez accidentellement à toute l''entreprise au lieu d''un seul collègue.'),
(8, 'La formule Excel sur laquelle vous bossez depuis 3 heures affiche #RÉF!.'),
(9, 'Un collègue vous demande un "point rapide de 5 minutes" qui va en durer 60.'),
(10, 'Votre webcam s''allume par surprise alors que vous étiez avachi sur votre siège.'),
(11, 'L''imprimante se bourre alors que vous essayez de sortir une seule page.'),
(12, 'Un client pose une question très technique dont vous n''avez absolument pas la réponse.'),
(13, 'Deux managers différents vous donnent deux tâches prioritaires et contradictoires.'),
(14, 'Vous réalisez que vous parliez dans le vide avec le micro coupé depuis 5 minutes.'),
(15, 'La date limite du projet passe de "vendredi prochain" à "cet après-midi".'),
(16, 'On vous "propose" de vous porter volontaire pour organiser l''Arbre de Noël du bureau.'),
(17, 'Un bug critique est découvert sur le site en production juste avant le week-end.'),
(18, 'La climatisation lâche en pleine canicule par 38°C.'),
(19, 'Vous oubliez le prénom d''un collègue que vous croisez tous les jours depuis deux ans.'),
(20, 'Votre PC force un redémarrage pour installer des mises à jour en plein travail.'),
(21, 'Quelqu''un a volé votre mug fétiche portant votre prénom dans la cuisine.'),
(22, 'Le client décide de changer toute la stratégie du projet à la semaine 12.'),
(23, 'Vous repérez une énorme faute de frappe dans la proposition commerciale tout juste envoyée.'),
(24, 'Slack ou Teams est en panne, empêchant toute communication interne.'),
(25, 'L''activité de Team Building de l''année s''avère être un parcours sportif forcé.');

INSERT INTO Response (IdResponse, IdSituation, Description, IdResponseType) VALUES 
-- Sit 1
(1, 1, 'S''excuser platement de manière proactive et offrir une remise commerciale.', 1),
(2, 1, 'Ignorer les e-mails du client en espérant qu''il finisse par oublier le problème.', 2),
-- Sit 2
(3, 2, 'Organiser une cellule de crise interservices intitulée "Urgence Caféine".', 1),
(4, 2, 'Paniquer en silence, éteindre son PC et rentrer chez soi pour la journée.', 2),
-- Sit 3
(5, 3, 'Décliner poliment en bloquant un créneau fictif de "Concentration Profonde".', 1),
(6, 3, 'Accepter l''invitation, couper sa caméra et soupirer bruyamment pendant tout le point.', 2),
-- Sit 4
(7, 4, 'Basculer instantanément sur le partage de connexion de son téléphone sans ciller.', 1),
(8, 4, 'Accuser le réseau du quartier et prétendre qu''il y a une coupure de courant générale.', 2),
-- Sit 5
(9, 5, 'Mener l''enquête auprès des RH grâce aux horaires de badgeage de la cuisine.', 1),
(10, 5, 'Coller un mot anonyme et passif-agressif écrit en majuscules sur le micro-ondes.', 2),
-- Sit 6
(11, 6, 'Rédiger une feuille de route bidon blindée de mots d''anglais corporate.', 1),
(12, 6, 'Laisser l''e-mail en non-lu et attendre sagement le lendemain matin pour répondre.', 2),
-- Sit 7
(13, 7, 'Renvoyer un e-mail d''excuses court, pro et Corporate expliquant la maladresse.', 1),
(14, 7, 'Assumer totalement et renvoyer un second e-mail encore plus absurde à toute la liste.', 2),
-- Sit 8
(15, 8, 'Reprendre proprement la formule depuis le début en utilisant un INDEX-EQUIV.', 1),
(16, 8, 'Masquer les lignes en erreur, mettre le reste en vert fluo et fermer le fichier.', 2),
-- Sit 9
(17, 9, 'Hocher la tête d''un air captivé tout en avançant discrètement sur ses vrais dossiers.', 1),
(18, 9, 'Prétexter un impératif urgent ou un appel client dans exactement 4 minutes.', 2),
-- Sit 10
(19, 10, 'Se figer comme une statue en priant pour qu''ils croient à un freeze de l''image.', 1),
(20, 10, 'Assumer le moment avec panache, même en peignoir léopard ou en t-shirt élimé.', 2),
-- Sit 11
(21, 11, 'Ouvrir les bacs et retirer délicatement la feuille selon la procédure officielle.', 1),
(22, 11, 'Soupirer longuement et laisser le problème au prochain malheureux qui passera.', 2),
-- Sit 12
(23, 12, 'Répondre habilement : "Bonne question, je valide cela en aparté avec mes équipes et je reviens vers vous."', 1),
(24, 12, 'Inventer un acronyme technique avec un aplomb total en espérant que personne ne vérifie.', 2),
-- Sit 13
(25, 13, 'Proposer une réunion tripartite d''urgence pour les forcer à trancher sur les priorités.', 1),
(26, 13, 'Ne faire aucune des deux tâches et regarder les deux managers s''écharper par e-mail.', 2),
-- Sit 14
(27, 14, 'Résumer brièvement vos arguments clés et enchaîner comme si de rien n''était.', 1),
(28, 14, 'Affirmer que ce long silence était une technique d''animation pour tester leur attention.', 2),
-- Sit 15
(29, 15, 'Se concentrer uniquement sur les livrables essentiels et mobiliser l''équipe en mode commando.', 1),
(30, 15, 'Fixer le vide avec un regard vitreux et accepter votre fin professionnelle proche.', 2),
-- Sit 16
(31, 16, 'Refuser poliment en expliquant que votre bande passante actuelle est saturée.', 1),
(32, 16, 'Se planquer dans les toilettes ou changer de couloir dès que l''organisateur approche.', 2),
-- Sit 17
(33, 17, 'Faire un rollback immédiat vers la version précédente et analyser les logs.', 1),
(34, 17, 'Rejeter la faute sur l''hébergeur cloud et suggérer d''attendre que "la panne passe".', 2),
-- Sit 18
(35, 18, 'Exiger la mise en place immédiate d''une dispense d''activité ou de télétravail pour sécurité.', 1),
(36, 18, 'Rester parfaitement immobile sur sa chaise pour ne pas générer de chaleur corporelle.', 2),
-- Sit 19
(37, 19, 'Utiliser des bottechouettes génériques comme "Salut l''ami !" ou "Ça va, champion ?"', 1),
(38, 19, 'Fuir tout contact visuel et raser les murs pour l''éviter définitivement.', 2),
-- Sit 20
(39, 20, 'Saisir l''occasion pour s''offrir une pause café prolongée hautement méritée.', 1),
(40, 20, 'Fixer intensément la jauge de pourcentage en espérant la faire avancer par la pensée.', 2),
-- Sit 21
(41, 21, 'Poster un message courtois et neutre sur Slack pour demander son retour au bercail.', 1),
(42, 21, 'Voler le mug d''un autre collègue en représailles pour imposer sa loi dans la cuisine.', 2),
-- Sit 22
(43, 22, 'Rédiger un devis d''avenant salé pour modification majeure du cahier des charges.', 1),
(44, 22, 'Dire oui avec un grand sourire mais ne pas changer une seule ligne de code.', 2),
-- Sit 23
(45, 23, 'Renvoyer le document corrigé dans la foulée avec la mention "Version Finale à jour".', 1),
(46, 23, 'Soutenir mordicus qu''il s''agit d''un parti pris stylistique moderne et disruptif.', 2),
-- Sit 24
(47, 24, 'Mettre à profit ce calme inattendu pour trier ses dossiers locaux ou ranger son bureau.', 1),
(48, 24, 'Considérer cet incident comme un jour férié surprise et s''accorder une sieste.', 2),
-- Sit 25
(49, 25, 'Y aller à reculons, faire le strict minimum et privilégier le buffet.', 1),
(50, 25, 'Simuler une terrible et mystérieuse contracture au mollet dès l''échauffement.', 2);


INSERT INTO ResponseFormation (IdResponse, IdFormation, Weight) VALUES 
(1, 4, 1), (1, 7, 1),
(2, 1, 1),
(3, 2, 1), (3, 8, 1),
(4, 3, 1), (4, 1, 1),
(5, 5, 1),
(6, 4, 1), (6, 7, 1),
(7, 3, 1),
(8, 1, 1), (8, 5, 1),
(9, 6, 1),
(10, 4, 1),
(11, 8, 1),
(12, 1, 1), (12, 5, 1),
(13, 7, 1),
(14, 8, 1),
(15, 6, 1),
(16, 1, 1), (16, 6, 1),
(17, 7, 1), (17, 8, 1),
(18, 5, 1),
(19, 3, 1),
(20, 3, 1),
(21, 4, 1),
(22, 4, 1), (22, 1, 1),
(23, 8, 1), (23, 7, 1),
(24, 8, 1),
(25, 5, 1),
(26, 1, 1), (26, 5, 1),
(27, 7, 1),
(28, 8, 1),
(29, 6, 1),
(30, 1, 1), (30, 4, 1),
(31, 5, 1), (31, 8, 1),
(32, 5, 1),
(33, 6, 1),
(34, 1, 1), (34, 8, 1),
(35, 3, 1),
(36, 1, 1),
(37, 7, 1),
(38, 5, 1),
(39, 2, 1),
(40, 4, 1),
(41, 7, 1),
(42, 4, 1),
(43, 6, 1), (43, 8, 1),
(44, 1, 1),
(45, 6, 1),
(46, 8, 1),
(47, 5, 1),
(48, 1, 1), (48, 3, 1),
(49, 7, 1), (49, 8, 1),
(50, 5, 1), (50, 4, 1);


INSERT INTO Describe (IdFormation, IdLevel) VALUES 
(2, 1),
(4, 1),
(3, 2),
(6, 2),
(1, 1),
(1, 2),
(5, 1),
(5, 2),
(7, 1),
(7, 2),
(8, 1),
(8, 2);
        ''';

        List<String> createStatements = creationScript
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        await db.transaction((txn) async {
          for (final statement in createStatements) {
            try {
              await txn.execute(statement);
            } catch (e) {
              // THIS is the line that will finally tell you the truth.
              debugPrint('❌ Failed statement:\n$statement\n--> $e');
              rethrow; // don't let it fail silently
            }
          }
        });
        List<String> insertBaseStatements = insertScriptBase
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        await db.transaction((txn) async {
          for (final statement in insertBaseStatements) {
            try {
              await txn.execute(statement);
            } catch (e) {
              // THIS is the line that will finally tell you the truth.
              debugPrint('❌ Failed statement:\n$statement\n--> $e');
              rethrow; // don't let it fail silently
            }
          }
        });
        List<String> insertPlaytestStatements = insertScriptPlaytest
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

        await db.transaction((txn) async {
          for (final statement in insertPlaytestStatements) {
            try {
              await txn.execute(statement);
            } catch (e) {
              // THIS is the line that will finally tell you the truth.
              debugPrint('❌ Failed statement:\n$statement\n--> $e');
              rethrow; // don't let it fail silently
            }
          }
        });

        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        debugPrint(
          '✅ Tables created: ${tables.map((t) => t['name']).toList()}',
        );
      },
    );
  }

  static Future<Database> get database async {
    final databasePath = join(await getDatabasesPath(), 'data.db');
    return openDatabase(databasePath);
  }

  //Inserts

  Future<void> insertAdmin(Admin admin) async {
    final db = await database;
    await db.insert(
      'Admin',
      admin.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertResponseType(ResponseType type) async {
    final db = await database;
    await db.insert(
      'ResponseType',
      type.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertCategory(Category category) async {
    final db = await database;
    await db.insert(
      'Category',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertLevel(Level level) async {
    final db = await database;
    await db.insert(
      'Level',
      level.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertSituation(Situation situation) async {
    final db = await database;

    final int insertedSituationId = await db.insert(
      'Situation',
      situation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (situation.responses != null) {
      for (var response in situation.responses!) {
        await insertResponse(
          Response(
            id: null,
            description: response.description,
            type: response.type,
            formations: response.formations,
          ),
          situationId: insertedSituationId, // Pass it directly
          executor: db,
        );
      }
    }
  }

  // Accept a DatabaseExecutor. If none is provided, fallback to the main db.
  Future<void> insertResponse(
    Response response, {
    int? situationId,
    DatabaseExecutor? executor,
  }) async {
    final client = executor ?? await database;

    final responseMap = response.toMap();
    if (situationId != null) {
      responseMap['IdSituation'] = situationId;
    }

    final int newResponseId = await client.insert(
      'Response',
      responseMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (response.formations != null) {
      for (var entry in response.formations!.entries) {
        await client.insert('ResponseFormation', {
          'IdResponse': newResponseId, // <--- Change from response.id
          'IdFormation': entry.key.id,
          'Weight': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<void> insertFormation(Formation formation) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Insert core Formation row
      await txn.insert(
        'Formation',
        formation.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Loop and link inside the "Describe" junction table
      for (var level in formation.levels) {
        await txn.insert('Describe', {
          'IdFormation': formation.id,
          'IdLevel': level.id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> insertResult(Result result) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Insert core Result row (handles Category foreign key automatically)
      final int resultId = await txn.insert('Result', {
        'Date': result.time != null
            ? result.time!.toIso8601String().split('T')[0]
            : DateTime.now().toIso8601String().split('T')[0],
        'Time': result.time != null
            ? result.time!.toIso8601String().split('T')[1]
            : DateTime.now().toIso8601String().split('T')[1],
        'IdCategory': result.category?.id ?? 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. Loop and link inside the "FormationResult" junction table
      for (var formation in result.formations!.entries) {
        await txn.insert('FormationResult', {
          'IdResult': resultId,
          'IdFormation': formation.key.id,
          'ResultWeight': formation.value, // Fallback default weight assignment
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateSituation(Situation situation) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Update the core Situation row
      await txn.update(
        'Situation',
        situation.toMap(),
        where: 'IdSituation = ?',
        whereArgs: [situation.id],
      );

      // 2. Remove any existing response links for this situation
      await txn.execute(
        'DELETE FROM ResponseFormation WHERE IdResponse IN (SELECT IdResponse FROM Response WHERE IdSituation = ?)',
        [situation.id],
      );

      // 3. Remove the old responses for this situation
      await txn.delete(
        'Response',
        where: 'IdSituation = ?',
        whereArgs: [situation.id],
      );

      // 4. Insert the new response set for this situation
      if (situation.responses != null) {
        for (final response in situation.responses!) {
          await insertResponse(
            response,
            situationId: situation.id,
            executor: txn,
          );
        }
      }
    });
  }

  Future<void> updateFormation(Formation formation) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Update the core Formation details
      await txn.update(
        'Formation',
        formation.toMap(),
        where: 'IdFormation = ?',
        whereArgs: [formation.id],
      );

      // 2. Clear existing level links in the "Describe" junction table
      await txn.delete(
        'Describe',
        where: 'IdFormation = ?',
        whereArgs: [formation.id],
      );

      // 3. Re-insert updated level links
      for (var level in formation.levels) {
        await txn.insert('Describe', {
          'IdFormation': formation.id,
          'IdLevel': level.id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> updateResponse(
    Response response, {
    int? situationId,
    DatabaseExecutor? executor,
  }) async {
    final client = executor ?? await database;

    // 1. Prepare data map
    final responseMap = response.toMap();
    if (situationId != null) {
      responseMap['IdSituation'] = situationId;
    }

    // 1. Update the core Response details
    await client.update(
      'Response',
      response.toMap(),
      where: 'IdResponse = ?',
      whereArgs: [response.id],
    );

    // 2. Clear existing formation links in the "ResponseFormation" junction table
    await client.delete(
      'ResponseFormation',
      where: 'IdResponse = ?',
      whereArgs: [response.id],
    );

    // 3. Re-insert updated formation links
    if (response.formations != null) {
      for (var entry in response.formations!.entries) {
        await client.insert('ResponseFormation', {
          'IdResponse': response.id,
          'IdFormation': entry.key.id,
          'Weight': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  //Gets
  Future<List<Admin>> getAdmins() async {
    final db = await database;
    final List<Map<String, Object?>> adminMaps = await db.query('Admin');
    return [
      for (final {
            'IdAdmin': id as int,
            'Login': login as String,
            'Hash': hash as String,
          }
          in adminMaps)
        Admin(id: id, login: login, hash: hash),
    ];
  }

  Future<List<Level>> getLevels() async {
    final db = await database;
    final List<Map<String, Object?>> levelMaps = await db.query('Level');
    return [
      for (final {'IdLevel': id as int, 'Label': label as String} in levelMaps)
        Level(id: id, label: label),
    ];
  }

  Future<List<Formation>> getFormations() async {
    final db = await database;
    final List<Map<String, Object?>> formationMaps = await db.query(
      'Formation',
    );
    return [
      for (final {
            'IdFormation': id as int,
            'Name': name as String,
            'Description': description as String,
          }
          in formationMaps)
        Formation(
          id: id,
          name: name,
          description: description,
          levels: [
            for (final {
                  'IdLevel': levelId as int,
                  'Label': levelLabel as String,
                }
                in await db
                    .query(
                      'Describe',
                      where: 'IdFormation = ?',
                      whereArgs: [id],
                      columns: ['IdLevel'],
                    )
                    .then(
                      (describeMaps) => describeMaps
                          .map((dm) => dm['IdLevel'] as int)
                          .toList(),
                    )
                    .then(
                      (levelIds) => db.query(
                        'Level',
                        where:
                            'IdLevel IN (${List.filled(levelIds.length, '?').join(',')})',
                        whereArgs: levelIds,
                      ),
                    ))
              Level(id: levelId, label: levelLabel),
          ],
        ),
    ];
  }

  Future<List<Situation>> getSituations() async {
    final db = await database;
    final List<Map<String, Object?>> situationMaps = await db.query(
      'Situation',
    );
    final List<Map<String, Object?>> responseMaps = await db.query('Response');
    final List<Map<String, Object?>> formationMaps = await db.query(
      'Formation',
    );
    final List<Map<String, Object?>> responseTypeMaps = await db.query(
      'ResponseType',
    );
    final List<Map<String, Object?>> responseFormationMaps = await db.query(
      'ResponseFormation',
    );
    final List<Map<String, Object?>> describeMaps = await db.query('Describe');
    final List<Map<String, Object?>> levelMaps = await db.query('Level');
    return [
      for (final {
            'IdSituation': id as int,
            'Description': description as String,
          }
          in situationMaps)
        Situation(
          id: id,
          description: description,
          responses: [
            for (final {
                  'IdResponse': responseId as int,
                  'Description': responseDescription as String,
                  'IdResponseType': typeId as int,
                }
                in responseMaps.where((r) => r['IdSituation'] == id))
              Response(
                id: responseId,
                description: responseDescription,
                type: ResponseType(
                  id: typeId,
                  label:
                      responseTypeMaps.firstWhere(
                            (rt) => rt['IdResponseType'] == typeId,
                          )['Label']
                          as String,
                ), // Fetch the actual label
                formations: <Formation, int>{
                  for (final {'IdFormation': formationId as int}
                      in responseFormationMaps.where(
                        (rf) => rf['IdResponse'] == responseId,
                      ))
                    Formation(
                      id: formationId,
                      name:
                          formationMaps.firstWhere(
                                (f) => f['IdFormation'] == formationId,
                              )['Name']
                              as String,
                      description:
                          formationMaps.firstWhere(
                                (f) => f['IdFormation'] == formationId,
                              )['Description']
                              as String,
                      levels: [
                        for (final {'IdLevel': levelId as int}
                            in describeMaps.where(
                              (d) => d['IdFormation'] == formationId,
                            ))
                          Level(
                            id: levelId,
                            label:
                                levelMaps.firstWhere(
                                      (l) => l['IdLevel'] == levelId,
                                    )['Label']
                                    as String,
                          ),
                      ],
                    ): responseFormationMaps.firstWhere(
                          (rf) =>
                              rf['IdResponse'] == responseId &&
                              rf['IdFormation'] == formationId,
                        )['Weight']
                        as int,
                },
              ),
          ],
        ),
    ];
  }

  Future<List<ResponseType>> getResponseType() async {
    final db = await database;
    final List<Map<String, Object?>> responseTypeMaps = await db.query(
      'ResponseType',
    );
    return [
      for (final {'IdResponseType': id as int, 'Label': label as String}
          in responseTypeMaps)
        ResponseType(id: id, label: label),
    ];
  }

  Future<List<Result>> getResult() async {
    final db = await database;

    // 1. Query all tables
    final resultMap = await db.query('Result');
    final formationResultMap = await db.query('FormationResult');
    final categoryMap = await db.query('Category');
    final describeMaps = await db.query('Describe');
    final levelMaps = await db.query('Level');
    final formationMap = await db.query(
      'Formation',
    ); // <-- NEW: needed for actual Formation data

    // 2. Build Category Lookup Map (ID -> Label)
    final categoryLookup = <int, String>{
      for (final c in categoryMap)
        if (c['IdCategory'] is int)
          c['IdCategory'] as int: (c['Label'] as String?) ?? '',
    };

    // 3. Build Level Lookup Map (ID -> Label)
    final levelLookup = <int, String>{
      for (final l in levelMaps)
        if (l['IdLevel'] is int)
          l['IdLevel'] as int: (l['Label'] as String?) ?? '',
    };

    // 4. Map Levels by Formation ID: Map<IdFormation, List<Level>>
    final levelsByFormation = <int, List<Level>>{};
    for (final d in describeMaps) {
      final formationId = d['IdFormation'] as int?;
      final levelId = d['IdLevel'] as int?;

      if (formationId != null && levelId != null) {
        final levelLabel = levelLookup[levelId] ?? '';
        levelsByFormation
            .putIfAbsent(formationId, () => [])
            .add(Level(id: levelId, label: levelLabel));
      }
    }

    // 5. Build Formation Lookup Map (ID -> Formation), reusing levelsByFormation
    final formationLookup = <int, Formation>{
      for (final f in formationMap)
        if (f['IdFormation'] is int)
          f['IdFormation'] as int: Formation(
            id: f['IdFormation'] as int,
            name: (f['Name'] as String?) ?? '',
            description: (f['Description'] as String?) ?? '',
            levels: levelsByFormation[f['IdFormation'] as int] ?? [],
          ),
    };

    // 6. Map Formations by Result ID: Map<IdResult, Map<Formation, int>>
    final formationsByResult = <int, Map<Formation, int>>{};
    for (final fr in formationResultMap) {
      final resultId = fr['IdResult'] as int?;
      final formationId = fr['IdFormation'] as int?;

      if (resultId != null && formationId != null) {
        final weight = (fr['ResultWeight'] as int?) ?? 0;
        final formation = formationLookup[formationId];

        if (formation != null) {
          formationsByResult.putIfAbsent(resultId, () => {})[formation] =
              weight;
        }
      }
    }

    // 7. Build final Result list
    final List<Result> results = [];
    for (final row in resultMap) {
      final idResult = row['IdResult'] as int?;
      if (idResult == null) continue;

      final date = row['Date'] as String?;
      final time = row['Time'] as String?;

      DateTime parsedDate;
      if (date != null && time != null) {
        parsedDate = DateTime.tryParse('$date $time') ?? DateTime.now();
      } else if (date != null) {
        parsedDate = DateTime.tryParse(date) ?? DateTime.now();
      } else {
        parsedDate = DateTime.now();
      }

      Category? category;
      final idCategory = row['IdCategory'] as int?;
      if (idCategory != null) {
        category = Category(
          id: idCategory,
          label: categoryLookup[idCategory] ?? '',
        );
      }

      results.add(
        Result(
          id: idResult,
          time: parsedDate,
          formations: formationsByResult[idResult] ?? {},
          category: category,
        ),
      );
    }

    return results;
  }

  Future<void> deleteFormation(Formation formation) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'Formation',
        where: 'IdFormation = ?',
        whereArgs: [formation.id],
      );
      await txn.delete(
        'ResponseFormation',
        where: 'IdFormation = ?',
        whereArgs: [formation.id],
      );
    });
  }

  Future<void> deleteSituation(Situation situation) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'Situation',
        where: 'IdSituation = ?',
        whereArgs: [situation.id],
      );

      for (var response in situation.responses!) {
        await txn.delete(
          'Response',
          where: 'IdResponse = ?',
          whereArgs: [response.id],
        );
        await txn.delete(
          'ResponseFormation',
          where: 'IdResponse = ?',
          whereArgs: [response.id],
        );
      }
    });
  }

  Future<void> deleteCategory(Category category) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'Category',
        where: 'IdCategory = ?',
        whereArgs: [category.id],
      );
    });
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final List<Map<String, Object?>> categoryMaps = await db.query('Category');
    return [
      for (final {'IdCategory': id as int, 'Label': label as String}
          in categoryMaps)
        Category(id: id, label: label),
    ];
  }
}
