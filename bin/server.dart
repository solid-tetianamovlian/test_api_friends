import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:supabase/supabase.dart';

// For Google Cloud Run, set _hostname to '0.0.0.0'.
const _hostname = 'localhost';

void main(List<String> args) async {
  var parser = ArgParser()..addOption('port', abbr: 'p');
  var result = parser.parse(args);

  // For Google Cloud Run, we respect the PORT environment variable
  var portStr = result['port'] ?? Platform.environment['PORT'] ?? '8080';
  var port = int.tryParse(portStr);

  if (port == null) {
    stdout.writeln('Could not parse port value "$portStr" into a number.');
    // 64: command line usage error
    exitCode = 64;
    return;
  }

  var handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  var server = await io.serve(handler, _hostname, port);
  print('Serving at http://${server.address.host}:${server.port}');
}

Future<shelf.Response> _echoRequest(shelf.Request request) async {
  switch (request.url.toString()) {
    case 'users':
      return _echoPersons(request);
    default:
      return shelf.Response.ok('Invalid url');
  }
}

Future<shelf.Response> _echoPersons(shelf.Request request) async {
  final client = SupabaseClient(
    'https://kgfclfpeeqjgpxovqxww.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtnZmNsZnBlZXFqZ3B4b3ZxeHd3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE2Njk3Mjg5OTIsImV4cCI6MTk4NTMwNDk5Mn0.uXz_1ZloY1yHWgOMrneTFvlDZVot2yle1AMrrMDeYa0',
  );

  // Retrieve data from 'persons' table
  final response = await client.from('persons').select().execute();

  var map = {'persons': response.data};

  return shelf.Response.ok(jsonEncode(map));
}
