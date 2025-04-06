import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'websocket_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // List untuk menyimpan history data gyroscope
  List<List<FlSpot>> gyroData = [[], [], []]; // x, y, z
  final int maxDataPoints = 50; // Jumlah maksimum data yang ditampilkan

  @override
  void initState() {
    super.initState();
    // Memulai server WebSocket saat aplikasi dijalankan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WebSocketService>(context, listen: false).startServer();
        final service = Provider.of<WebSocketService>(context, listen: false);
        service.addListener(() {
          updateChartData(service);
        });
      }
    });
  }

  void updateChartData(WebSocketService service) {
    // Hanya update chart jika widget masih mounted
    if (!mounted) return;

    setState(() {
      // Mendapatkan timestamp yang diskalakan sebagai sumbu x (menggunakan index saja untuk kesederhanaan)
      final now = gyroData[0].length.toDouble();
      
      // Menambahkan data baru
      gyroData[0].add(FlSpot(now, service.filteredGyroX));
      gyroData[1].add(FlSpot(now, service.filteredGyroY));
      gyroData[2].add(FlSpot(now, service.filteredGyroZ));
      
      // Membuang data lama jika melebihi batas maksimum
      if (gyroData[0].length > maxDataPoints) {
        for (int i = 0; i < 3; i++) {
          gyroData[i].removeAt(0);
          
          // Menggeser semua x value agar dimulai dari 0
          for (int j = 0; j < gyroData[i].length; j++) {
            gyroData[i][j] = FlSpot(j.toDouble(), gyroData[i][j].y);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    // Menutup server WebSocket saat aplikasi ditutup
    if (mounted) {
      Provider.of<WebSocketService>(context, listen: false).stopServer();
    }
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
            child: SingleChildScrollView(
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
                  
                  // Grafik Line Chart
                  const Text('Gyroscope Data Chart:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: const FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            minX: 0,
                            maxX: (maxDataPoints - 1).toDouble(),
                            minY: -1,
                            maxY: 1,
                            lineBarsData: [
                              // X Gyro
                              LineChartBarData(
                                spots: gyroData[0],
                                isCurved: true,
                                color: Colors.red,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                              // Y Gyro
                              LineChartBarData(
                                spots: gyroData[1],
                                isCurved: true,
                                color: Colors.green,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                              // Z Gyro
                              LineChartBarData(
                                spots: gyroData[2],
                                isCurved: true,
                                color: Colors.blue,
                                barWidth: 2,
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Legenda untuk grafik
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('X-Axis', Colors.red),
                        const SizedBox(width: 16),
                        _buildLegendItem('Y-Axis', Colors.green),
                        const SizedBox(width: 16),
                        _buildLegendItem('Z-Axis', Colors.blue),
                      ],
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
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}