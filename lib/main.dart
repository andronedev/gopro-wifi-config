import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoPro Update',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController diskController = TextEditingController();
  TextEditingController goproNameController = TextEditingController();
  TextEditingController goproPasswordController = TextEditingController();

  void createUpdateFiles() async {
    Directory? appDocDir = await getApplicationDocumentsDirectory();
    if (appDocDir != null) {
      String updateDirPath = '${appDocDir.path}/UPDATE';
      Directory(updateDirPath).createSync();

      Map<String, dynamic> settingsData = {
        "current_password": "",
        "token": "",
        "wifi_ap": {
          "ssid": goproNameController.text,
          "password": goproPasswordController.text
        },
        "wifi_networks": []
      };
      String settingsJson = jsonEncode(settingsData);
      File('$updateDirPath/settings.in').writeAsStringSync(settingsJson);

      String updateContent = '# Camera upgrade rules file\nOPTIONS:6';
      File('$updateDirPath/update.11.txt').writeAsStringSync(updateContent);

      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Succès'),
            content: const Text(
                'Tâche terminée avec succès !, maintenant vous pouvez retirer la carte SD et la mettre dans votre GoPro.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GoPro Update'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Sélectionnez le disque à utiliser (par ex. "D:") :',
              style: TextStyle(fontSize: 16.0),
            ),
            TextField(
              controller: diskController,
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Nom de la GoPro :',
              style: TextStyle(fontSize: 16.0),
            ),
            TextField(
              controller: goproNameController,
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Mot de passe de la GoPro :',
              style: TextStyle(fontSize: 16.0),
            ),
            TextField(
              controller: goproPasswordController,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              child: const Text('Créer les fichiers de mise à jour'),
              onPressed: () {
                createUpdateFiles();
              },
            ),
          ],
        ),
      ),
    );
  }
}
