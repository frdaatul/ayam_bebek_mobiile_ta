import 'package:flutter/material.dart';
import '../../models/cart_model.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Detail Produk"),
        backgroundColor: const Color(0xFF624D42),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔥 HERO IMAGE
          Hero(
            tag: product["name"],
            child: Image.network(
              product["image"],
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),

          // 🔥 CONTENT
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NAMA
                  Text(
                    product["name"],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // HARGA
                  Text(
                    _formatRupiah(product["price"]),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF624D42),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // DESKRIPSI
                  const Text(
                    "Deskripsi Produk",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Produk berkualitas tinggi untuk kebutuhan ternak Anda. "
                    "Diproduksi dengan bahan terbaik dan aman digunakan.",
                  ),

                  const Spacer(),

                  // 🔥 BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        CartModel.addItem(product);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Berhasil ditambahkan"),
                            backgroundColor: Colors.green,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                      ),
                      child: const Text("Tambah ke Keranjang"),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 🔥 FORMAT RUPIAH
  String _formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}";
  }
}