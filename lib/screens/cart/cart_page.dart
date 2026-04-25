import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../checkout/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    final cartItems = CartModel.getItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Keranjang"),
        backgroundColor: const Color(0xFF624D42),
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            // IMAGE
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item["image"],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),

                            const SizedBox(width: 12),

                            // TEXT
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["name"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _formatRupiah(item["price"]),
                                    style: const TextStyle(
                                      color: Color(0xFF624D42),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // DELETE BUTTON
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  cartItems.removeAt(index);
                                });

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text("Item dihapus"),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),

                _buildBottomSection(context),
              ],
            ),
    );
  }

  // 🔥 EMPTY STATE
  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Keranjang kamu kosong",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 🔥 BOTTOM TOTAL + BUTTON
  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total",
                style: TextStyle(fontSize: 16),
              ),
              Text(
                _formatRupiah(CartModel.getTotalPrice()),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckoutPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("Checkout"),
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