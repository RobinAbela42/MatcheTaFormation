/// link.dart is the main file to  link the database to the app. 

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Situation {

  final int id; 
  final List<Response>? responses;
  final String description;

  const Situation({required this.id, this.responses, required this.description});

  Map<String, Object?> toMap() {
    return {'IdSituation': id, 'Description': description};
  }

}

class Response {

  final int id;
  final int idSituation;
  final Map<Formation, int>? formations;
  final int type;
  final String? description;

  const Response({required this.id, required this.idSituation, this.formations, this.description, required this.type});
  
}

class Formation {

  final int id;
  final String name; 
  final String description;

  const Formation ({required this.id, required this.name, required this.description});

  Map<String, Object?> toMap(){
    return {'IdFormation' : id, 'Name' : name, 'Description': description};
  }

}

class Result {
  final int id;
  final List<Formation> formations;
  final DateTime time;

  const Result({required this.id, required this.formations, required this.time});

}

class Admin {
  final int id;
  final String login;
  final String password;

  const Admin({required this.id ,required this.login, required this.password});

}

class Category {
  final int id;
  final String label;

  const Category({required this.id, required this.label});
}

void main() async {
    // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  // Open the database and store the reference.
  final database = openDatabase(
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    join(await getDatabasesPath(), 'data.db'),
  );

  

  Future<void> insertFormation(Formation formation) async {
    // Get a reference to the database.
    final db = await database;

    // Insert the Dog into the correct table. You might also specify the
    // `conflictAlgorithm` to use in case the same dog is inserted twice.
    //
    // In this case, replace any previous data.
    await db.insert(
      'Formation',
      formation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // await insertFormation(Formation(id: 1, name: "INFO", description: "La formation est une formation."));
}