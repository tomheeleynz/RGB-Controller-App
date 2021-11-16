import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}): super(key:key);

  @override 
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
{
  // List of Devices to conenct to
  List<BluetoothDevice> devices = <BluetoothDevice>[];
  List<BluetoothCharacteristic> characteristics = <BluetoothCharacteristic>[];
  BluetoothDevice? connectedDevice;

  // RGB Values
  double red = 0;
  double green = 0;
  double blue = 0;

  // Connect To Device
  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();

    // Get Services From Device
    List<BluetoothService> allServices = await device.discoverServices();

    // Check Services
    for (var service in allServices) {
      if (service.uuid == Guid("cf696fda-1abf-4772-be09-2e52d5e8ec3e")) {
        print("Found Service");
        List<BluetoothCharacteristic> chars = service.characteristics;
        for (BluetoothCharacteristic c in chars) {
          setState(() {
            characteristics.add(c);
          });
        }
      }
    }
    
    setState(() {
      connectedDevice = device;
    });
  }


  Future<void> writeRGBColor() async {
    List<int> valueArray = [red.toInt(), green.toInt(), blue.toInt()];
    await characteristics[0].write(valueArray);
  }

  Future<void> setLEDState(int value) async {
    await characteristics[1].write([value]);
  }

  // Scan For Devices
  void scanDevices() {
    setState(() { devices.clear(); });
    
    FlutterBlue instance = FlutterBlue.instance;

    instance.startScan(timeout: const Duration(seconds: 4));

    instance.scanResults.listen((results) {
      for (ScanResult r in results) {
        setState(() {
          devices.add(r.device);
        });
      } 
    });

    instance.stopScan();
  }

  @override 
  Widget build(BuildContext context) {
    return  Scaffold(
      drawer: Drawer(
        child: ListView.builder(
          itemCount: devices.length,
          itemBuilder: (BuildContext context, int index) {
            return GestureDetector(
              onTap: () {
                connectToDevice(devices[index]);
              },
              child: Container(
                color: Colors.amber,
                height: 50,
                child: Text(devices[index].name),
              ),
            );
          }
        ), 
      ),
      appBar: AppBar(
        title: const Text("Bluetooth App"),
      ),
      body: Column(
        children: [
          if (connectedDevice == null)
            Center(
              child: TextButton(
                onPressed: () { 
                  scanDevices(); 
                }, 
                child: const Text("Scan Devices")
              ),
            )
          else
            Column(
              children: [
                Slider(
                  value: red,
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (double value) {
                    setState(() {
                      red = value;
                    });
                  }
                ),Slider(
                  value: green,
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (double value) {
                    setState(() {
                      green = value;
                    });
                  }
                ),Slider(
                  value: blue,
                  min: 0,
                  max: 255,
                  divisions: 255,
                  onChanged: (double value) {
                    setState(() {
                      blue = value;
                    });
                  }
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setLEDState(1);
                      }, 
                      child: const Text("Turn On")
                    ), 
                     TextButton(
                      onPressed: () {
                        setLEDState(0);
                      }, 
                      child: const Text("Turn Off")
                    ),  
                    TextButton(
                      onPressed: () {
                        writeRGBColor();
                      }, 
                      child: const Text("Set Color")
                    ), 
                  ],
                ),
                Center(
                  child: TextButton(
                    onPressed: () { 
                      connectedDevice!.disconnect();
                      setState(() {
                        connectedDevice = null;
                      });
                    }, 
                    child: const Text("Disconnect")
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }
}