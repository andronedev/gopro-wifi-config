import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:win32/win32.dart';
// Size

void main() async {
  // set the windows size
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await DesktopWindow.setMaxWindowSize(const Size(1000, 900));
    await DesktopWindow.setMinWindowSize(const Size(1000, 900));
    await DesktopWindow.setWindowSize(const Size(1000, 900));
    await DesktopWindow.setFullScreen(false);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'GoPro Update',
      theme: FluentThemeData(
        accentColor: Colors.blue,
      ),
      themeMode: ThemeMode.dark,
      darkTheme: FluentThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController goproNameController = TextEditingController();
  TextEditingController goproPasswordController = TextEditingController();

  String selectedDisk = '';
  List<String> diskItems = [];

  bool _loading = true;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    getAvailableDisks();
  }

  void getAvailableDisks() {
    setState(() {
      _loading = true;
    });

    final bitmask = GetLogicalDrives();
    final drives = <String>[];

    for (int i = 0; i < 26; i++) {
      final mask = 1 << i;
      if ((bitmask & mask) != 0) {
        final drive = '${String.fromCharCode(65 + i)}:\\';

        final buffer = calloc<ffi.Uint16>(MAX_PATH).cast<Utf16>();
        final result = GetVolumeInformation(
          TEXT(drive),
          buffer,
          MAX_PATH,
          ffi.nullptr,
          ffi.nullptr,
          ffi.nullptr,
          ffi.nullptr,
          0,
        );
        if (result != 0) {
          final label = buffer.unpackString(MAX_PATH);
          drives.add('$drive - $label');
        } else {
          drives.add(drive);
        }
        calloc.free(buffer);
      }
    }

    diskItems = drives;

    if (diskItems.isNotEmpty) {
      selectedDisk = diskItems.first;
    }

    Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _loading = false;
      });
    });
  }

  void reset() {
    setState(() {
      _success = false;
    });
  }

  void resetAll() {
    setState(() {
      _success = false;
      goproNameController.text = '';
      goproPasswordController.text = '';
    });
  }

  void createUpdateFiles() async {
    setState(() {
      _loading = true;
    });
    String selectedDiskLetter = selectedDisk.substring(0, 1);

    if (selectedDiskLetter.isNotEmpty) {
      String updateDirPath = '$selectedDiskLetter:\\UPDATE';
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
    }
    setState(() {
      _loading = false;
      _success = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
          title: Row(children: [
        const Text('GoPro Hero+ Wifi Update'),
        const SizedBox(width: 10.0),
        _loading ? const ProgressRing() : const SizedBox()
      ])),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _success
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tout est prêt !, Vous pouvez maintenant mettre à jour votre GoPro en insérant la carte SD dans la caméra.',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  Button(
                    child: const Text('Recommencer'),
                    onPressed: () {
                      resetAll();
                      reset();
                    },
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Sélectionnez le disque à utiliser :',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      ComboBox<String>(
                        items: diskItems.map((String value) {
                          return ComboBoxItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        value: selectedDisk,
                        onChanged: (String? value) {
                          if (value != null) {
                            setState(() {
                              selectedDisk = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 10.0),
                      Button(
                        child: const Text('Actualiser'),
                        onPressed: () {
                          diskItems = [];
                          getAvailableDisks();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Nom du réseau de la GoPro :',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  TextBox(
                    controller: goproNameController,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Mot de passe du réseau de la GoPro :',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  PasswordBox(
                    controller: goproPasswordController,
                  ),
                  const SizedBox(height: 20.0),
                  Button(
                    child: const Text('Mettre à jour les paramètres'),
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
