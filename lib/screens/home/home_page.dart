import 'package:flutter/material.dart';
import '../product/product_page.dart';
import '../scan/scan_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AyamBebek App"),
        backgroundColor: const Color(0xFF624D42),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔥 HEADER / GREETING
            const Text(
              "Halo 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Selamat datang di aplikasi AyamBebek",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // 🔥 BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF624D42),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.store, color: Colors.white, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Belanja kebutuhan ternak dengan mudah 🐔",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 MENU
            const Text(
              "Menu Utama",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 CARD MENU PRODUK
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProductPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shopping_bag, color: Color(0xFF624D42)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Lihat Produk",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),

            // 🔥 CARD MENU SCAN
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScanPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Color(0xFF624D42)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Scan Barcode",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // 🔥 FOOTER
            const Center(
              child: Text(
                "v1.0 AyamBebek App",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}