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
  
  // Tambahkan variabel bool untuk rendering chart
  bool showXAxisChart = true;
  bool showYAxisChart = true;
  bool showZAxisChart = true;

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
      final now = rawGyroData[0].length.toDouble();
      
      // Menambahkan data raw
      rawGyroData[0].add(FlSpot(now, service.gyroX));
      rawGyroData[1].add(FlSpot(now, service.gyroY));
      rawGyroData[2].add(FlSpot(now, service.gyroZ));
      
      // Menambahkan data filtered
      filteredGyroData[0].add(FlSpot(now, service.filteredGyroX));
      filteredGyroData[1].add(FlSpot(now, service.filteredGyroY));
      filteredGyroData[2].add(FlSpot(now, service.filteredGyroZ));
      
      // Membuang data lama jika melebihi batas maksimum
      if (rawGyroData[0].length > maxDataPoints) {
        for (int i = 0; i < 3; i++) {
          rawGyroData[i].removeAt(0);
          filteredGyroData[i].removeAt(0);
          
          // Menggeser semua x value agar dimulai dari 0
          for (int j = 0; j < rawGyroData[i].length; j++) {
            rawGyroData[i][j] = FlSpot(j.toDouble(), rawGyroData[i][j].y);
            filteredGyroData[i][j] = FlSpot(j.toDouble(), filteredGyroData[i][j].y);
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
                  
                  // X-Axis Chart
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('X-Axis Gyroscope Data:', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              // Toggle switch for X-Axis chart
                              Row(
                                children: [
                                  const Text('Show Chart:'),
                                  Switch(
                                    value: showXAxisChart,
                                    onChanged: (value) {
                                      setState(() {
                                        showXAxisChart = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (showXAxisChart) 
                            SizedBox(
                              height: 250,
                              child: LineChart(
                                _buildLineChartData(0, 'X-Axis'),
                              ),
                            )
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 100.0),
                                child: Text('Chart rendering is disabled',
                                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // X-Axis Legend
                  if (showXAxisChart)
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
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Y-Axis Gyroscope Data:', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              // Toggle switch for Y-Axis chart
                              Row(
                                children: [
                                  const Text('Show Chart:'),
                                  Switch(
                                    value: showYAxisChart,
                                    onChanged: (value) {
                                      setState(() {
                                        showYAxisChart = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (showYAxisChart) 
                            SizedBox(
                              height: 250,
                              child: LineChart(
                                _buildLineChartData(1, 'Y-Axis'),
                              ),
                            )
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 100.0),
                                child: Text('Chart rendering is disabled',
                                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Y-Axis Legend
                  if (showYAxisChart)
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
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Z-Axis Gyroscope Data:', 
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              // Toggle switch for Z-Axis chart
                              Row(
                                children: [
                                  const Text('Show Chart:'),
                                  Switch(
                                    value: showZAxisChart,
                                    onChanged: (value) {
                                      setState(() {
                                        showZAxisChart = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (showZAxisChart) 
                            SizedBox(
                              height: 250,
                              child: LineChart(
                                _buildLineChartData(2, 'Z-Axis'),
                              ),
                            )
                          else
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 100.0),
                                child: Text('Chart rendering is disabled',
                                  style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Z-Axis Legend
                  if (showZAxisChart)
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
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Axis', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Raw', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Filtered', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('X-Axis'),
                              Text(service.gyroX.toStringAsFixed(4)),
                              Text(service.filteredGyroX.toStringAsFixed(4)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Y-Axis'),
                              Text(service.gyroY.toStringAsFixed(4)),
                              Text(service.filteredGyroY.toStringAsFixed(4)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Z-Axis'),
                              Text(service.gyroZ.toStringAsFixed(4)),
                              Text(service.filteredGyroZ.toStringAsFixed(4)),
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
                  const SizedBox(height: 20),
                  // Tambahkan tombol untuk toggle semua grafik
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Jika semua grafik saat ini ditampilkan, matikan semua. Jika tidak, nyalakan semua
                          bool newState = !(showXAxisChart && showYAxisChart && showZAxisChart);
                          showXAxisChart = newState;
                          showYAxisChart = newState;
                          showZAxisChart = newState;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(
                        (showXAxisChart && showYAxisChart && showZAxisChart) 
                            ? 'Disable All Charts' 
                            : 'Enable All Charts',
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
    final List<Color> rawColors = [Colors.red, Colors.green, Colors.blue];
    final List<Color> filteredColors = [Colors.redAccent.shade100, Colors.green.shade200, Colors.blue.shade200];
    
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
          sideTitles: const SideTitles(
            showTitles: true,
            reservedSize: 30,
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