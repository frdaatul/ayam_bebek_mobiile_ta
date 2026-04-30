import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'product_detail_page.dart';
import '../cart/cart_page.dart';
import '../../models/cart_model.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List products = [];
  List stores = [];
  List categories = [];

  bool isLoading = true;
  int? selectedStoreId;
  int? selectedCategoryId;
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    await Future.wait([
      fetchStores(),
      fetchCategories(),
      fetchProducts(),
    ]);
    if (mounted) setState(() => isLoading = false);
  }

  // 🔥 AMBIL DATA TOKO
  Future<void> fetchStores() async {
    try {
      final response = await http.get(Uri.parse("http://192.168.22.39:8000/api/stores"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => stores = data['data']);
      }
    } catch (e) {
      debugPrint("Error Stores: $e");
    }
  }

  // 🔥 AMBIL DATA KATEGORI
  Future<void> fetchCategories() async {
    try {
      String url = "http://192.168.22.39:8000/api/categories";
      if (selectedStoreId != null) url += "?store_id=$selectedStoreId";

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) setState(() => categories = data['data']);
      }
    } catch (e) {
      debugPrint("Error Categories: $e");
    }
  }

  // 🔥 AMBIL DATA PRODUK
  Future<void> fetchProducts() async {
    try {
      String url = "http://192.168.22.39:8000/api/products";
      List<String> params = [];
      if (selectedStoreId != null) params.add("store_id=$selectedStoreId");
      if (selectedCategoryId != null) params.add("category_id=$selectedCategoryId");
      if (searchQuery.isNotEmpty) params.add("q=$searchQuery");

      if (params.isNotEmpty) url += "?" + params.join("&");

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            products = data['data'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error Products: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _searchController,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: "Cari pakan favoritmu...",
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 18, color: Colors.orange),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() { searchQuery = ""; isLoading = true; });
                        fetchProducts();
                      },
                    )
                  : null,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild untuk ikon X
                
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  if (value.length >= 2 || value.isEmpty) {
                    setState(() { 
                      searchQuery = value; 
                      isLoading = true; 
                    });
                    fetchProducts();
                  }
                });
              },
              onSubmitted: (value) {
                setState(() { searchQuery = value; isLoading = true; });
                fetchProducts();
              },
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage())).then((_) => setState(() {})),
              ),
              if (CartModel.cartItems.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${CartModel.cartItems.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── PREMIUM FILTER SECTION ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            child: Column(
              children: [
                // Store Selector
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: stores.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildFilterChip("Semua Toko", selectedStoreId == null, () {
                          setState(() { selectedStoreId = null; selectedCategoryId = null; isLoading = true; });
                          fetchCategories(); fetchProducts();
                        });
                      }
                      final store = stores[index - 1];
                      return _buildFilterChip(store['name'], selectedStoreId == store['id'], () {
                        setState(() { selectedStoreId = store['id']; selectedCategoryId = null; isLoading = true; });
                        fetchCategories(); fetchProducts();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Category Selector
                SizedBox(
                  height: 30,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildCategoryChip("Semua", selectedCategoryId == null, () {
                          setState(() { selectedCategoryId = null; isLoading = true; });
                          fetchProducts();
                        });
                      }
                      final cat = categories[index - 1];
                      return _buildCategoryChip(cat['name'], selectedCategoryId == cat['id'], () {
                        setState(() { selectedCategoryId = cat['id']; isLoading = true; });
                        fetchProducts();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── PRODUCT GRID ──────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                : products.isEmpty
                    ? _buildEmptyState()
                    : GridView.builder(
                        padding: const EdgeInsets.all(10),
                        itemCount: products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.65,
                        ),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          String imageUrl = "https://via.placeholder.com/150";
                          if (product['images'] != null && (product['images'] as List).isNotEmpty) {
                            imageUrl = product['images'][0]['image_url'];
                          }
                          return _buildProductCard(product, imageUrl);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.white,
          border: Border.all(color: isSelected ? Colors.orange[800]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.orange[800] : Colors.black54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(dynamic product, String imageUrl) {
    final rawPrice = product["price"];
    int price = 0;
    if (rawPrice != null) {
      // API returns decimal string like "15000.00", int.tryParse fails on this.
      price = double.tryParse(rawPrice.toString())?.toInt() ?? 0;
    }

    return InkWell(
      onTap: () => Navigator.push(
        context, 
        MaterialPageRoute(builder: (_) => ProductDetailPage(product: product))
      ).then((_) => setState(() {})),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 30),
                      ),
                    ),
                    if (product['stock'] < 10 && product['stock'] > 0)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          color: Colors.orange.withOpacity(0.9),
                          child: const Text("Stok Terbatas", style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product["name"] ?? "Produk",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13, height: 1.3),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatRupiah(price),
                          style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              "${product['sold_count'] ?? 0} Terjual",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const Spacer(),
                            Text(
                              "Stok: ${product['stock'] ?? 0}",
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.storefront, size: 10, color: Colors.grey[500]),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                product['store'] != null ? (product['store']['name'] ?? "") : "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[500], fontSize: 9),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Produk tidak ditemukan", style: TextStyle(color: Colors.grey[600], fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatRupiah(int price) {
    return "Rp${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}";
  }
}
