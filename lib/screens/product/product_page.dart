import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'product_detail_page.dart';
import '../cart/cart_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // 🔥 AMBIL DATA API
  Future<void> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.2.5/ayam_bebek_api/get_products.php"),
      );

      if (response.statusCode == 200) {
        setState(() {
          products = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produk"),
        backgroundColor: const Color(0xFF624D42),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            },
          )
        ],
      ),

      // 🔥 LOADING
      body: isLoading
          ? const Center(child: CircularProgressIndicator())

          // 🔥 EMPTY
          : products.isEmpty
              ? const Center(child: Text("Belum ada produk"))

              // 🔥 DATA
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration:
                                  const Duration(milliseconds: 300),
                              pageBuilder: (_, __, ___) =>
                                  ProductDetailPage(product: product),
                              transitionsBuilder:
                                  (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // HERO IMAGE
                              Hero(
                                tag: product["name"],
                                child: ClipRRect(
                                  borderRadius:
                                      const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    product["image"],
                                    height: 130,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product["name"],
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatRupiah(
                                          int.parse(product["price"].toString())),
                                      style: const TextStyle(
                                        color:
                                            Color(0xFF624D42),
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // FORMAT RUPIAH
  String _formatRupiah(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    )}";
  }
}