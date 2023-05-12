import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const PaymentPage(
        upiLink:
            'upi://pay?pa=7898026293@ybl&pn=******6293&mc=0000&mode=00&purpose=00&cu=INR&am=500',
      ),
    );
  }
}

class MyHomePage extends HookWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cameraController = MobileScannerController();
    final found = useState(false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
      ),
      body: MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            final Uint8List? image = capture.image;
            for (final barcode in barcodes) {
              debugPrint('Barcode found! ${barcode.rawValue}');
            }
            if (!found.value) {
              HapticFeedback.vibrate();
              found.value = true;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentPage(upiLink: barcodes.first.rawValue!),
                ),
              ).then((value) => found.value = false);
            }

            // ignore: use_build_context_synchronously
          }),
    );
  }
}

class PaymentPage extends StatelessWidget {
  final String upiLink;
  static const platform = MethodChannel('example.com/channel');

  const PaymentPage({Key? key, required this.upiLink}) : super(key: key);

  // Future<List<Application>> getApps() {
  //   return DeviceApps.getInstalledApplications(
  //       includeAppIcons: true, onlyAppsWithLaunchIntent: true);
  // }

  Future<List<Map<dynamic, dynamic>>?> getApps() async {
    try {
      return platform.invokeListMethod('getApps', {});
    } on PlatformException catch (e) {
      print(e);
      return Future.value(List.empty());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder(
            future: getApps(),
            builder:
                (ctx, AsyncSnapshot<List<Map<dynamic, dynamic>>?> snapshot) {
              if (snapshot.hasData) {
                final List<Map<dynamic, dynamic>>? apps = snapshot.data;
                //print(apps);
                if (apps != null) {
                  return Column(
                    children: [
                      Center(
                        child: Text(upiLink),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                        height: 90,
                        child: Scrollbar(
                          thickness: 0,
                          child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: apps.length,
                              shrinkWrap: true,
                              itemBuilder: (c, i) => _appIcon(apps[i])),
                        ),
                      )
                    ],
                  );
                } else {
                  return const Center(
                    child: Text('No apps installed'),
                  );
                }
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text('Got some error'),
                );
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            }),
      ),
    );
  }

  Uint8List convertImage(String str) {
    final List<int> codeUnits = str.codeUnits;
    final Uint8List uint8list = Uint8List.fromList(codeUnits);
    return uint8list;
  }

  Widget _appIcon(Map<dynamic, dynamic> app) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () async {
          platform.invokeMethod('initiateTransaction',
              {'package': app['packageName'], 'url': upiLink});
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Builder(
                builder: (c) => app['icon'] != null
                    ? Image.memory(
                        base64.decode(app['icon']),
                        width: 64,
                        height: 64,
                      )
                    : Container()),
            Container(
              alignment: Alignment.center,
              child: Text(
                app['appName'] ?? app['packageName'],
                textAlign: TextAlign.center,
              ),
            )
          ],
        ),
      ),
    );
  }
}
