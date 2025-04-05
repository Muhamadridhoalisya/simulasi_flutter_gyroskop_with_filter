import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'websocket_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => WebSocketService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 WebSocket Server',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'ESP32 WebSocket Server'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    // Memulai server WebSocket saat aplikasi dijalankan
    Provider.of<WebSocketService>(context, listen: false).startServer();
  }

  @override
  void dispose() {
    // Menutup server WebSocket saat aplikasi ditutup
    Provider.of<WebSocketService>(context, listen: false).stopServer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Consumer<WebSocketService>(
        builder: (context, service, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Server Status: ${service.isRunning ? "Running" : "Stopped"}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Listening on: ${service.isRunning ? "ws://localhost:8080" : "Not listening"}'),
                        Text('Client connected: ${service.isClientConnected ? "Yes" : "No"}'),
                        const SizedBox(height: 8),
                        Text('Data Rate: ${service.dataRatePerSecond} data/second', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Gyroscope Data (Raw):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('X: ${service.gyroX.toStringAsFixed(4)}'),
                        Text('Y: ${service.gyroY.toStringAsFixed(4)}'),
                        Text('Z: ${service.gyroZ.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Gyroscope Data (Filtered):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('X: ${service.filteredGyroX.toStringAsFixed(4)}'),
                        Text('Y: ${service.filteredGyroY.toStringAsFixed(4)}'),
                        Text('Z: ${service.filteredGyroZ.toStringAsFixed(4)}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Timestamp: ${service.timestamp}'),
                        Text('Last Message Received: ${service.lastMessageTime}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        if (!service.isRunning) {
                          service.startServer();
                        }
                      },
                      child: const Text('Start Server'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (service.isRunning) {
                          service.stopServer();
                        }
                      },
                      child: const Text('Stop Server'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}