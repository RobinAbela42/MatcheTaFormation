/// link.dart is the main file to  link the database to the app.

import 'dart:async';

// import 'dart:developer' as developer;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:match_ta_formation_0/main.dart';
// import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';



class Situation {
  final int id;
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
  final int id;
  final Map<Formation, int>? formations;
  final ResponseType type;
  final String? description;

  const Response({
    required this.id,
    this.formations,
    this.description,
    required this.type,
  });

  Map<String, Object?> toMap() {
    return {
      'IdResponse': id,
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
  final int id;
  final String name;
  final String description;
  final List<Level> levels;

  const Formation({
    required this.id,
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
}

class Result {
  final int id;
  final List<Formation> formations;
  final DateTime time;
  final Category category;

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
          .toIso8601String(), // Formatted safely for SQL text/datetime storage
      'IdCategory':
          category.id, // Foreign Key relation resolved from the object
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
  final int id;
  final String label;

  const Category({required this.id, required this.label});

  Map<String, Object?> toMap() {
    return {'IdCategory': id, 'Label': label};
  }

  @override
  String toString() {
    return 'Category(id: $id, label: $label)';
  }
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
    await db.insert(
      'Situation',
      situation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertResponse(Response response, {int? situationId}) async {
    final db = await database;

    // Use a transaction to ensure all insertions succeed together
    await db.transaction((txn) async {
      // 1. Prepare data map and inject the optional Situation foreign key if provided
      final responseMap = response.toMap();
      if (situationId != null) {
        responseMap['IdSituation'] = situationId;
      }

      // 2. Insert the core Response
      await txn.insert(
        'Response',
        responseMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 3. Insert relationship pairs into the junction table
      if (response.formations != null) {
        for (var entry in response.formations!.entries) {
          await txn.insert('ResponseFormation', {
            'IdResponse': response.id,
            'IdFormation': entry.key.id,
            'Weight': entry.value, // The map value represents the weight
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
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
      await txn.insert(
        'Result',
        result.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Loop and link inside the "FormationResult" junction table
      for (var formation in result.formations) {
        await txn.insert('FormationResult', {
          'IdResult': result.id,
          'IdFormation': formation.id,
          'ResultWeight': 0, // Fallback default weight assignment
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
  // await insertFormation(Formation(id: 1, name: "INFO", description: "La formation est une formation.", levels: List.empty()));

//Gets 
  Future<List<Admin>> getAdmins() async {
    final db = await database;
    final List<Map<String, Object?>> adminMaps = await db.query('Admin');
    return [
      for (final {'IdAdmin': id as int, 'Login': login as String, 'Hash': hash as String} in adminMaps)
        Admin(id: id, login: login, hash: hash)
    ];
  }  


  Future<List<Formation>> getFormations() async {
    final db = await database;
    final List<Map<String, Object?>> formationMaps = await db.query('Formation');
    return [
      for (final {'IdFormation': id as int, 'Name': name as String, 'Description': description as String} in formationMaps)
        Formation(id: id, name: name, description: description, levels: [])
    ];
  }
}