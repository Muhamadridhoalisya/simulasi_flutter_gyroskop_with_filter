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
  // List untuk menyimpan history data gyroscope (raw dan filtered)
  List<List<FlSpot>> rawGyroData = [[], [], []]; // x, y, z raw data
  List<List<FlSpot>> filteredGyroData = [[], [], []]; // x, y, z filtered data
  final int maxDataPoints = 100; // Jumlah maksimum data yang ditampilkan

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

  List<DateTime> timestamps = [];

  void updateChartData(WebSocketService service) {
    // Hanya update chart jika widget masih mounted
    if (!mounted) return;

    setState(() {
      // Mendapatkan timestamp yang diskalakan sebagai sumbu x (menggunakan index saja untuk kesederhanaan)
      // final now = rawGyroData[0].length.toDouble();
      final currentTime = DateTime.now();
      timestamps.add(currentTime);
      
      // Menambahkan data raw
      rawGyroData[0].add(FlSpot(timestamps.length.toDouble(), service.gyroX));
      rawGyroData[1].add(FlSpot(timestamps.length.toDouble(), service.gyroY));
      rawGyroData[2].add(FlSpot(timestamps.length.toDouble(), service.gyroZ));
      
      // Menambahkan data filtered
      filteredGyroData[0].add(FlSpot(timestamps.length.toDouble(), service.filteredGyroX));
      filteredGyroData[1].add(FlSpot(timestamps.length.toDouble(), service.filteredGyroY));
      filteredGyroData[2].add(FlSpot(timestamps.length.toDouble(), service.filteredGyroZ));
      
      // Membuang data lama jika melebihi batas maksimum
      if (rawGyroData[0].length > maxDataPoints) {
        for (int i = 0; i < 3; i++) {
          rawGyroData[i].removeAt(0);
          filteredGyroData[i].removeAt(0);
        }
        timestamps.removeAt(0);
        
        // Perbarui posisi X untuk semua data
        for (int j = 0; j < rawGyroData[0].length; j++) {
          rawGyroData[0][j] = FlSpot(j.toDouble(), rawGyroData[0][j].y);
          rawGyroData[1][j] = FlSpot(j.toDouble(), rawGyroData[1][j].y);
          rawGyroData[2][j] = FlSpot(j.toDouble(), rawGyroData[2][j].y);
          filteredGyroData[0][j] = FlSpot(j.toDouble(), filteredGyroData[0][j].y);
          filteredGyroData[1][j] = FlSpot(j.toDouble(), filteredGyroData[1][j].y);
          filteredGyroData[2][j] = FlSpot(j.toDouble(), filteredGyroData[2][j].y);
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
                  
                  // X-Axis Chart
                  const Text('X-Axis Gyroscope Data:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 250,
                        child: LineChart(
                          _buildLineChartData(0, 'X-Axis'),
                        ),
                      ),
                    ),
                  ),
                  
                  // X-Axis Legend
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Raw', Colors.red),
                        const SizedBox(width: 16),
                        _buildLegendItem('Filtered', Colors.redAccent.shade100),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Y-Axis Chart
                  const Text('Y-Axis Gyroscope Data:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 250,
                        child: LineChart(
                          _buildLineChartData(1, 'Y-Axis'),
                        ),
                      ),
                    ),
                  ),
                  
                  // Y-Axis Legend
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Raw', Colors.green),
                        const SizedBox(width: 16),
                        _buildLegendItem('Filtered', Colors.green.shade200),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Z-Axis Chart
                  const Text('Z-Axis Gyroscope Data:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        height: 250,
                        child: LineChart(
                          _buildLineChartData(2, 'Z-Axis'),
                        ),
                      ),
                    ),
                  ),
                  
                  // Z-Axis Legend
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Raw', Colors.blue),
                        const SizedBox(width: 16),
                        _buildLegendItem('Filtered', Colors.blue.shade200),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Text('Current Gyroscope Data:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Axis', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Raw', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Filtered', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('X-Axis'),
                              // Text('${service.gyroX.toStringAsFixed(4)}'),
                              // Text('${service.filteredGyroX.toStringAsFixed(4)}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Y-Axis'),
                              // Text('${service.gyroY.toStringAsFixed(4)}'),
                              // Text('${service.filteredGyroY.toStringAsFixed(4)}'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Z-Axis'),
                              // Text('${service.gyroZ.toStringAsFixed(4)}'),
                              // Text('${service.filteredGyroZ.toStringAsFixed(4)}'),
                            ],
                          ),
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
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (service.isRunning) {
                          service.stopServer();
                        } else {
                          service.startServer();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: service.isRunning 
                            ? Colors.redAccent 
                            : Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        service.isRunning ? 'Stop Server' : 'Start Server',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  LineChartData _buildLineChartData(int axisIndex, String title) {
    // Warna untuk setiap axis (raw dan filtered)
    final List<Color> rawColors = [Colors.red, Colors.purple, Colors.blue];
    final List<Color> filteredColors = [Colors.blue, Colors.green, Colors.orange];
    
    return LineChartData(
      gridData: const FlGridData(
        show: false,
        horizontalInterval: 50, // Interval 50 sesuai permintaan
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 50, // Interval 50 sesuai permintaan
            reservedSize: 40,
          ),
        ),
        bottomTitles: AxisTitles(
          axisNameWidget: Text(title),
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              // Cek apakah indeks valid dan ada timestamp untuk indeks tersebut
              if (value >= 0 && value < timestamps.length && value % 20 == 0) {
                // Hanya tampilkan label setiap 20 data untuk mencegah terlalu padat
                final time = timestamps[value.toInt()];
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const SizedBox.shrink(); // Tidak menampilkan label untuk semua titik
            },
          ),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: true),
      minX: 0,
      maxX: (maxDataPoints - 1).toDouble(),
      minY: -300, // Range Y dari -300 sampai 300 sesuai permintaan
      maxY: 300,
      lineBarsData: [
        // Raw data
        LineChartBarData(
          spots: rawGyroData[axisIndex],
          isCurved: true,
          color: rawColors[axisIndex],
          barWidth: 2,
          dotData: const FlDotData(show: false),
        ),
        // Filtered data
        LineChartBarData(
          spots: filteredGyroData[axisIndex],
          isCurved: true,
          color: filteredColors[axisIndex],
          barWidth: 2,
          dotData: const FlDotData(show: false),
          dashArray: [8,8],
        ),
      ],
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