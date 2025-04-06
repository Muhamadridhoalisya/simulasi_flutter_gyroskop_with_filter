import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'websocket_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // List untuk menyimpan history data gyroscope (raw dan filtered)
  List<List<double>> rawGyroData = [[], [], []]; // x, y, z raw data
  List<List<double>> filteredGyroData = [[], [], []]; // x, y, z filtered data
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

  void updateChartData(WebSocketService service) {
    // Hanya update chart jika widget masih mounted
    if (!mounted) return;

    setState(() {
      // Menambahkan data raw
      rawGyroData[0].add(service.gyroX);
      rawGyroData[1].add(service.gyroY);
      rawGyroData[2].add(service.gyroZ);
      
      // Menambahkan data filtered
      filteredGyroData[0].add(service.filteredGyroX);
      filteredGyroData[1].add(service.filteredGyroY);
      filteredGyroData[2].add(service.filteredGyroZ);
      
      // Membuang data lama jika melebihi batas maksimum
      if (rawGyroData[0].length > maxDataPoints) {
        for (int i = 0; i < 3; i++) {
          rawGyroData[i].removeAt(0);
          filteredGyroData[i].removeAt(0);
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
                        child: CustomPaint(
                          size: const Size(double.infinity, 250),
                          painter: GyroscopeChartPainter(
                            rawData: rawGyroData[0],
                            filteredData: filteredGyroData[0],
                            maxDataPoints: maxDataPoints,
                            rawColor: Colors.red,
                            filteredColor: Colors.green,
                            axisTitle: 'X-Axis',
                          ),
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
                        _buildLegendItem('Filtered', Colors.green),
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
                        child: CustomPaint(
                          size: const Size(double.infinity, 250),
                          painter: GyroscopeChartPainter(
                            rawData: rawGyroData[1],
                            filteredData: filteredGyroData[1],
                            maxDataPoints: maxDataPoints,
                            rawColor: Colors.blue,
                            filteredColor: Colors.orange,
                            axisTitle: 'Y-Axis',
                          ),
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
                        _buildLegendItem('Raw', Colors.blue),
                        const SizedBox(width: 16),
                        _buildLegendItem('Filtered', Colors.orange),
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
                        child: CustomPaint(
                          size: const Size(double.infinity, 250),
                          painter: GyroscopeChartPainter(
                            rawData: rawGyroData[2],
                            filteredData: filteredGyroData[2],
                            maxDataPoints: maxDataPoints,
                            rawColor: Colors.pink,
                            filteredColor: Colors.brown,
                            axisTitle: 'Z-Axis',
                          ),
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
                        _buildLegendItem('Raw', Colors.pink),
                        const SizedBox(width: 16),
                        _buildLegendItem('Filtered', Colors.brown),
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

class GyroscopeChartPainter extends CustomPainter {
  final List<double> rawData;
  final List<double> filteredData;
  final int maxDataPoints;
  final Color rawColor;
  final Color filteredColor;
  final String axisTitle;
  
  // Constants for chart layout
  final double _padding = 40.0;
  final double _yAxisWidth = 50.0;
  final double _xAxisHeight = 40.0;
  final double _minY = -300.0;
  final double _maxY = 300.0;
  final double _gridInterval = 50.0;
  
  GyroscopeChartPainter({
    required this.rawData,
    required this.filteredData, 
    required this.maxDataPoints,
    required this.rawColor,
    required this.filteredColor,
    required this.axisTitle,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = Rect.fromLTWH(
      _padding + _yAxisWidth, 
      _padding, 
      size.width - _padding * 2 - _yAxisWidth, 
      size.height - _padding * 2 - _xAxisHeight
    );
    
    _drawBackground(canvas, chartRect);
    _drawYAxis(canvas, chartRect);
    _drawXAxis(canvas, chartRect);
    
    if (rawData.isNotEmpty) {
      _drawDataSeries(canvas, chartRect, rawData, rawColor);
    }
    
    if (filteredData.isNotEmpty) {
      _drawDataSeries(canvas, chartRect, filteredData, filteredColor, isDashed: true);
    }
  }
  
  void _drawBackground(Canvas canvas, Rect chartRect) {
    // Draw chart background
    final bgPaint = Paint()
      ..color = Colors.grey.shade50
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke;
    
    canvas.drawRect(chartRect, bgPaint);
    canvas.drawRect(chartRect, borderPaint);
    
    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke;
    
    final int totalGridLines = ((_maxY - _minY) / _gridInterval).ceil();
    final double yRange = _maxY - _minY;
    
    for (int i = 0; i <= totalGridLines; i++) {
      final double y = _minY + i * _gridInterval;
      final double yPos = chartRect.bottom - ((y - _minY) / yRange * chartRect.height);
      
      if (y >= _minY && y <= _maxY) {
        canvas.drawLine(
          Offset(chartRect.left, yPos),
          Offset(chartRect.right, yPos),
          gridPaint,
        );
      }
    }
  }
  
  void _drawYAxis(Canvas canvas, Rect chartRect) {
    const textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 12,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw Y-axis labels
    final int totalLabels = ((_maxY - _minY) / _gridInterval).ceil();
    final double yRange = _maxY - _minY;
    
    for (int i = 0; i <= totalLabels; i++) {
      final double y = _minY + i * _gridInterval;
      final double yPos = chartRect.bottom - ((y - _minY) / yRange * chartRect.height);
      
      if (y >= _minY && y <= _maxY) {
        textPainter.text = TextSpan(
          text: y.toInt().toString(),
          style: textStyle,
        );
        
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(chartRect.left - textPainter.width - 8, yPos - textPainter.height / 2),
        );
      }
    }
  }
  
  void _drawXAxis(Canvas canvas, Rect chartRect) {
    const textStyle = TextStyle(
      color: Colors.black87,
      fontSize: 12,
    );
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw X-axis title
    textPainter.text = TextSpan(
      text: axisTitle,
      style: textStyle.copyWith(fontWeight: FontWeight.bold),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        chartRect.center.dx - textPainter.width / 2,
        chartRect.bottom + 20,
      ),
    );
  }
  
  void _drawDataSeries(Canvas canvas, Rect chartRect, List<double> data, Color color, {bool isDashed = false}) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final path = Path();
    final double yRange = _maxY - _minY;
    
    // Start at the first data point
    if (data.isNotEmpty) {
      final double x = chartRect.left;
      final double normalizedY = (data[0] - _minY) / yRange;
      final double y = chartRect.bottom - normalizedY * chartRect.height;
      path.moveTo(x, y);
    }
    
    // Add all points to the path
    for (int i = 1; i < data.length; i++) {
      final double x = chartRect.left + (i / (maxDataPoints - 1)) * chartRect.width;
      final double normalizedY = (data[i] - _minY) / yRange;
      final double y = chartRect.bottom - normalizedY * chartRect.height;
      
      // Clamp Y to the chart boundaries
      final double clampedY = y.clamp(chartRect.top, chartRect.bottom);
      path.lineTo(x, clampedY);
    }
    
    // Draw the line
    if (isDashed) {
      // Draw dashed line
      final dashPath = Path();
      const dashWidth = 4.0;
      const gapWidth = 4.0;
      
      var dashPathMetrics = path.computeMetrics().toList();
      for (var pathMetric in dashPathMetrics) {
        var distance = 0.0;
        var isDraw = true;
        while (distance < pathMetric.length) {
          var length = isDraw ? dashWidth : gapWidth;
          if (distance + length > pathMetric.length) {
            length = pathMetric.length - distance;
          }
          
          if (isDraw) {
            dashPath.addPath(
              pathMetric.extractPath(distance, distance + length),
              Offset.zero,
            );
          }
          
          distance += length;
          isDraw = !isDraw;
        }
      }
      
      canvas.drawPath(dashPath, paint);
    } else {
      canvas.drawPath(path, paint);
    }
  }
  
  @override
  bool shouldRepaint(GyroscopeChartPainter oldDelegate) {
    return oldDelegate.rawData != rawData || 
           oldDelegate.filteredData != filteredData;
  }
}