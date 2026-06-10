/// link.dart is the main file to  link the database to the app. 

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Situation {

  final int id; 
  final List<int> id_responses;
  final String description;

  const Situation({required this.id, required this.id_responses, required this.description});

}

class Response {

  final int id;
  final int id_situation;
  final List<int>? id_formations;
  final List<int>? weights;
  final int type;
  final String? description;

  const Response({required this.id, required this.id_situation, this.id_formations, this.description, required this.type, this.weights});
  
}

class Formation {

  final int id;
  final String name; 
  final String description;

  const Formation ({required this.id, required this.name, required this.description});

}

class Result {
  final int id;
  final List<int> id_formations;
  final DateTime time;

  const Result({required this.id, required this.id_formations, required this.time});

}

class Admin {
  final int id;
  final String login;
  final String password;

  const Admin({required this.id ,required this.login, required this.password});

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

}