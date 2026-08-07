import 'package:flutter/material.dart';

import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/database/app_database.dart';

void main() {
  final database = AppDatabase();
  runApp(App(database: database));
}
