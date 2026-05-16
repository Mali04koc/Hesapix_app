import 'package:flutter/material.dart';

enum DatabaseType { firebase, postgres }

class DatabaseManager extends ChangeNotifier {
  static final DatabaseManager _instance = DatabaseManager._internal();

  factory DatabaseManager() {
    return _instance;
  }

  DatabaseManager._internal();

  DatabaseType _currentDatabase = DatabaseType.firebase;

  DatabaseType get currentDatabase => _currentDatabase;

  void setDatabase(DatabaseType type) {
    if (_currentDatabase != type) {
      _currentDatabase = type;
      notifyListeners();
    }
  }

  bool get isPostgres => _currentDatabase == DatabaseType.postgres;
  bool get isFirebase => _currentDatabase == DatabaseType.firebase;
}
