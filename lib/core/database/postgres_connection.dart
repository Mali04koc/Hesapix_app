import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

class PostgresConnection {
  static final PostgresConnection _instance = PostgresConnection._internal();

  factory PostgresConnection() {
    return _instance;
  }

  PostgresConnection._internal();

  Connection? _connection;

  Future<Connection> getConnection() async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }

    String host = 'localhost';
    if (!kIsWeb && Platform.isAndroid) {
      host = '10.0.2.2'; // Android emülatöründen bilgisayardaki localhost'a erişmek için
    }
   
    _connection = await Connection.open(
      Endpoint(
        host: host, 
        port: 5432,
        database: 'hesapix_db',
        username: 'postgres',
        password: 'mk200613', 
      ),
      settings: ConnectionSettings(
        sslMode: SslMode.disable, // Localhost olduğu için şimdilik kapalı
      ),
    ).timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception("PostgreSQL bağlantısı zaman aşımına uğradı. Lütfen veritabanının çalıştığından emin olun.");
    });

    return _connection!;
  }
}
