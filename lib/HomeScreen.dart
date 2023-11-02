import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:titu_marriage_app/Qrcode.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String inviteStatus = "Scan to be invited";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFFFFFFF),
      appBar: AppBar(
        title: Text(
          "Scan Invite",
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 30,
            ),
            const Image(
              image: AssetImage("assets/wed.png"),
              width: 200,
              height: 200,
            ),
            const SizedBox(
              height: 100,
            ),
            Center(
                child: Text(inviteStatus,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ))),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              height: 70,
              child: ElevatedButton(
                onPressed: () async {
                  // Navigate to the QR code scanning screen
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRScannerScreen(),
                    ),
                  );

                  // Handle the result from the QRScannerScreen
                  if (result != null && result is bool && result) {
                    setState(() {
                      // Update inviteStatus with additional details
                      inviteStatus =
                          'Successfully invited on ${DateTime.now().toString()}';
                    });
                  }
                },
                child: Text(
                  "Scan QR Code",
                  style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
