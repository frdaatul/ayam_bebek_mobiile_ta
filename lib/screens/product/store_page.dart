import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'product_detail_page.dart';

class StorePage extends StatefulWidget {
  final Map<String, dynamic> store;

  const StorePage({super.key, required this.store});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  List products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStoreProducts();
  }

  Future<void> fetchStoreProducts() async {
    try {
      // Fetch products filtered by this store
      final response = await http.get(Uri.parse("http://192.168.22.39:8000/api/products?store_id=${widget.store['id']}"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          products = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung total penjualan dari semua produk yang ada di toko ini
    int totalSold = 0;
    for (var p in products) {
      totalSold += (p['sold_count'] as num?)?.toInt() ?? 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // ── SHOPEE STYLE STORE HEADER ───────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.orange[800],
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Gradient Premium
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.orange[900]!.withOpacity(0.8),
                          Colors.orange[800]!,
                        ],
                      ),
                    ),
                  ),
                  // Store Info Content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),
                        Row(
                          children: [
                            // Logo
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.grey[100],
                                backgroundImage: NetworkImage(widget.store['logo_url'] ?? ""),
                                onBackgroundImageError: (_, __) {},
                                child: widget.store['logo_url'] == null 
                                  ? Icon(Icons.storefront, color: Colors.orange[800], size: 28)
                                  : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Name & Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.store['name'] ?? "Toko Pakan",
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.white70, size: 10),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.store['address'] ?? "Alamat tidak tersedia",
                                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Total Penjualan Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      "$totalSold+ Produk Terjual",
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Action Buttons
                        Row(
                          children: [
                            _buildHeaderBtn("CHAT", Icons.chat_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── STORE PRODUCTS GRID ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Semua Produk (${products.length})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),

          isLoading
              ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return _buildProductCard(product);
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    String imageUrl = "https://via.placeholder.com/200";
    if (product['images'] != null && product['images'].isNotEmpty) {
      imageUrl = product['images'][0]['image_url'];
    }

    final rawPrice = product["price"];
    int price = double.tryParse(rawPrice.toString())?.toInt() ?? 0;

    return InkWell(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (context) => ProductDetailPage(product: product))
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk dengan Aspect Ratio terjaga
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                  ),
                ),
              ),
            ),
            // Informasi Produk
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? "Produk",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(price),
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${product['sold_count'] ?? 0} Terjual",
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      if ((product['stock'] ?? 0) < 5)
                        const Text(
                          "Stok Limit",
                          style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(int price) {
    return "Rp${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}";
  }

  Widget _buildHeaderBtn(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
