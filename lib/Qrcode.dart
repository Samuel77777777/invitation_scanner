import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  bool isScanning = true;
  late Timer _timeoutTimer;

  @override
  void initState() {
    super.initState();
    // Set an initial timeout duration (in seconds)
    const int timeoutDuration = 30;
    // Start the timer for scanning timeout
    _timeoutTimer = Timer(Duration(seconds: timeoutDuration), _handleTimeout);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("QR Code Scanner"),
        centerTitle: true,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // QRView widget for displaying the camera preview and handling QR code scanning
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.deepPurple,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
            ),
          ),

          // Animated loading indicator while scanning is in progress
          if (isScanning)
            SpinKitFadingCircle(
              color: Colors.deepPurple, // Adjust color as needed
              size: 50.0,
            ),
        ],
      ),
    );
  }

  // Callback when the QRView widget is created
  void _onQRViewCreated(QRViewController controller) {
    print('QRView created');
    this.controller = controller;

    // Listen to the scannedDataStream for incoming QR code data
    controller.scannedDataStream.listen((scanData) async {
      print('Scanned Data Stream: $scanData');

      // Extract the key from the scanned data
      String scannedKey = extractKeyFromLink(scanData as String);

      // Check if the scanned key is empty
      if (scannedKey.isNotEmpty) {
        // Store the scanned key in a variable
        String scannedKeyVariable = scannedKey;

        // Stop the scanning animation
        setState(() {
          isScanning = false;
        });

        // Search in the database based on the key and perform verification
        await _searchInDatabase(scannedKeyVariable);

        // Reset the scan for a new QR code
        _resetScan();
      }
    });
  }

  // Extract the key from the scanned link
  String extractKeyFromLink(String link) {
    try {
      // Parse the link
      Uri uri = Uri.parse(link);

      // Extract the last part of the path as the key
      String path = uri.path;
      String key = path.substring(path.lastIndexOf('/') + 1);

      return key;
    } catch (error) {
      // Handle parsing errors
      throw 'Error parsing link: $error';
    }
  }

  // Search in the database based on the key and perform verification
  Future<void> _searchInDatabase(String scannedKey) async {


    try {
      print('Searching in database for Key: $scannedKey');

      // Make an API request to get invite data from the database
      final getInviteResponse = await http.get(
        Uri.parse('https://invites.onrender.com/api/invites/$scannedKey'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('API Response: ${getInviteResponse.statusCode}');

   

      if (getInviteResponse.statusCode == 200) {
        // Parse the response JSON
        final Map<String, dynamic> inviteData =
            json.decode(getInviteResponse.body);

        print('Invite Data: $inviteData');

        // Check if the key is not used (modify this condition based on your application logic)
        if (inviteData.containsKey('verified') && !inviteData['verified']) {
          // If the key is not used, show the success message
          _showSnackBar('Success: Key verified successfully', Colors.green);

          // For example, update the verification status in the database
          await _updateVerifiedStatus(scannedKey);
        } else {
          // If the key is already used, reset the scan
          _resetScan();
        }
      } else {
        // If the database search fails, reset the scan
        _resetScan();
      }
    } catch (error) {
      // Hide the loading indicator (if needed)

      // Handle errors and show a snackbar with an error message
      _showSnackBar('Error: $error', Colors.red);

      // Reset the scan
      _resetScan();
    }
  }

  // Simulate updating the verified status of the invite in the database
  Future<void> _updateVerifiedStatus(String inviteId) async {
    try {
      await http.put(
        Uri.parse('https://invites.onrender.com/api/invites/$inviteId'),
        body: {'verified': true.toString()},
      );
    } catch (error) {
      // Handle exceptions, e.g., network issues
      _showSnackBar('Error: $error', Colors.red);
    }
  }

  // Handle the scanning timeout
  void _handleTimeout() {
    _showSnackBar('Timeout: QR code is not valid', Colors.red);

    // Navigate back to the home screen
    Navigator.pop(context);
  }

  // Reset the scan for a new QR code
  void _resetScan() {
    if (isScanning) {
      // Stop the scanning animation
      setState(() {
        isScanning = false;
      });

      // Pause the camera
      controller.pauseCamera();

      // Reset the timer for scanning timeout
      _timeoutTimer.cancel();

      // Reset any other parameters as needed
      // ...
    }
  }

  // Display a snackbar with a message
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: GoogleFonts.montserrat(
            color: const Color.fromRGBO(255, 255, 255, 1),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            // Hide the current snackbar
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Cancel the timer for scanning timeout
    _timeoutTimer.cancel();

    // Dispose of the QR code scanner controller
    controller.dispose();

    super.dispose();
  }
}
