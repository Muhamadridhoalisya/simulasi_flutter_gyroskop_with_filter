// websocket_service.dart

import 'dart:async';
import 'dart:io';
// import 'dart:typed_data';
import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'dart:convert';

class WebSocketService extends ChangeNotifier {
  HttpServer? _server;
  WebSocket? _webSocket;
  bool isRunning = false;
  bool isClientConnected = false;

  // Data yang akan disimpan dari ESP32
  double gyroX = 0.0;
  double gyroY = 0.0;
  double gyroZ = 0.0;
  double filteredGyroX = 0.0;
  double filteredGyroY = 0.0;
  double filteredGyroZ = 0.0;
  int timestamp = 0;
  String lastMessageTime = '-';
  
  // Data untuk tracking rate
  int _messageCount = 0;
  int dataRatePerSecond = 0;
  DateTime _lastRateCalculation = DateTime.now();
  Timer? _rateCalculationTimer;

  // Fungsi untuk memulai server WebSocket
  Future<void> startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
      isRunning = true;
      notifyListeners();
      
      debugPrint('WebSocket server started on ws://localhost:8080');
      
      // Mulai timer untuk menghitung rate data
      _startRateCalculationTimer();
      
      _server!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then((WebSocket webSocket) {
            _handleWebSocket(webSocket);
          }).catchError((error) {
            debugPrint('Error during WebSocket upgrade: $error');
            request.response.close();
          });
        } else {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.close();
        }
      });
    } catch (e) {
      debugPrint('Error starting WebSocket server: $e');
      isRunning = false;
      notifyListeners();
    }
  }

  // Timer untuk menghitung rate data per detik
  void _startRateCalculationTimer() {
    _rateCalculationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final difference = now.difference(_lastRateCalculation).inMilliseconds;
      
      // Hitung jumlah data per detik
      if (difference > 0) {
        dataRatePerSecond = (_messageCount * 1000 / difference).round();
        _messageCount = 0;
        _lastRateCalculation = now;
        notifyListeners();
      }
    });
  }

  // Fungsi untuk menangani koneksi WebSocket
  void _handleWebSocket(WebSocket webSocket) {
    _webSocket = webSocket;
    isClientConnected = true;
    notifyListeners();
    
    debugPrint('Client connected');
    
    // Menangani pesan dari klien
    webSocket.listen(
      (dynamic message) {
        _processMessage(message);
      },
      onDone: () {
        debugPrint('Client disconnected');
        isClientConnected = false;
        _webSocket = null;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('WebSocket error: $error');
        isClientConnected = false;
        _webSocket = null;
        notifyListeners();
      },
      cancelOnError: true,
    );
  }

  // Fungsi untuk memproses pesan biner yang diterima
  void _processMessage(dynamic message) {
    if (message is! List<int>) {
      debugPrint('Received non-binary message: $message');
      return;
    }

    // Memastikan ukuran pesan sesuai (28 byte: 6 float + 1 uint32)
    if (message.length != 28) {
      debugPrint('Invalid message length: ${message.length} bytes (expected 28 bytes)');
      return;
    }

    try {
      // Increment counter untuk tracking rate
      _messageCount++;
      
      // Decode pesan biner
      ByteData byteData = ByteData.view(Uint8List.fromList(message).buffer);
      
      // Membaca nilai float (masing-masing 4 byte)
      gyroX = byteData.getFloat32(0, Endian.little);
      gyroY = byteData.getFloat32(4, Endian.little);
      gyroZ = byteData.getFloat32(8, Endian.little);
      filteredGyroX = byteData.getFloat32(12, Endian.little);
      filteredGyroY = byteData.getFloat32(16, Endian.little);
      filteredGyroZ = byteData.getFloat32(20, Endian.little);
      
      // Membaca timestamp (4 byte)
      timestamp = byteData.getUint32(24, Endian.little);
      
      // Update waktu pesan diterima
      DateTime now = DateTime.now();
      lastMessageTime = '${now.hour}:${now.minute}:${now.second}.${now.millisecond}';
      
      debugPrint('Received binary data:');
      debugPrint('Gyro X: $gyroX, Y: $gyroY, Z: $gyroZ');
      debugPrint('Filtered Gyro X: $filteredGyroX, Y: $filteredGyroY, Z: $filteredGyroZ');
      debugPrint('Timestamp: $timestamp');
      
      // Memberi tahu listeners (UI) bahwa data telah diperbarui
      notifyListeners();
    } catch (e) {
      debugPrint('Error decoding binary message: $e');
    }
  }

  // Fungsi untuk mengirim pesan ke klien yang terhubung
  void sendMessage(String message) {
    if (_webSocket != null && isClientConnected) {
      _webSocket!.add(message);
    }
  }

  // Fungsi untuk mengirim data biner ke klien yang terhubung
  void sendBinaryMessage(List<int> data) {
    if (_webSocket != null && isClientConnected) {
      _webSocket!.add(data);
    }
  }

  // Fungsi untuk menghentikan server WebSocket
  void stopServer() {
    if (_rateCalculationTimer != null) {
      _rateCalculationTimer!.cancel();
      _rateCalculationTimer = null;
    }
    
    if (_webSocket != null) {
      _webSocket!.close();
      _webSocket = null;
      isClientConnected = false;
    }
    
    if (_server != null) {
      _server!.close();
      _server = null;
      isRunning = false;
    }
    
    notifyListeners();
    debugPrint('WebSocket server stopped');
  }
}