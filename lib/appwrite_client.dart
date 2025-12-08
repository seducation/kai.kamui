import 'package:appwrite/appwrite.dart';

// THIS IS A MOCK IMPLEMENTATION FOR DEMONSTRATION PURPOSES
// In a real application, you would use a service like flutter_dotenv
// to load these values from a .env file, which is not checked into version control.
// For example:
//
// import 'package:flutter_dotenv/flutter_dotenv.dart';
//
// final String endpoint = dotenv.env['APPWRITE_ENDPOINT']!;
// final String projectId = dotenv.env['APPWRITE_PROJECT_ID']!;

class AppwriteClient {
  static const String _endpoint = 'https://cloud.appwrite.io/v1';
  static const String _projectId = '65d52242337756f77c3d';

  Client get client => Client()
    ..setEndpoint(_endpoint)
    ..setProject(_projectId);

  Databases get databases => Databases(client);
  Account get account => Account(client);
}
