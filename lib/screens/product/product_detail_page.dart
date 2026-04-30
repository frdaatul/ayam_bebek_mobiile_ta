import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/cart_model.dart';
import '../../models/favorite_model.dart';
import '../../utils/notification_helper.dart';
import '../cart/cart_page.dart';
import '../checkout/checkout_page.dart';
import 'store_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  bool _isFavorited = false;

  @override
  void initState() {
    super.initState();
    _isFavorited = FavoriteModel.isFavorited(widget.product['id']);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final List images = product['images'] ?? [];
    final List descriptions = product['descriptions'] ?? [];
    final List specifications = product['specifications'] ?? [];

    String firstImageUrl = "https://via.placeholder.com/400x300";
    if (images.isNotEmpty) {
      firstImageUrl = images[0]['image_url'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          "Detail Produk",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {
              final String productUrl = "http://192.168.22.39:8000/product/${product['id']}";
              Share.share(
                'Cek produk bagus ini: ${product['name']}\n\nBeli di sini: $productUrl',
                subject: 'Bagikan Produk ${product['name']}',
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                ).then((_) => setState(() {})),
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Slider
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  if (images.isEmpty)
                    _buildSingleImage(firstImageUrl)
                  else
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        _buildImageSlider(images),
                        if (images.length > 1)
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: images.asMap().entries.map((entry) {
                                return Container(
                                  width: 6.0,
                                  height: 6.0,
                                  margin: const EdgeInsets.symmetric(horizontal: 3.0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentImageIndex == entry.key ? Colors.orange : Colors.grey[300],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),

            // Product Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Builder(
                    builder: (context) {
                      final List variants = product['variants'] ?? [];
                      if (variants.isEmpty) {
                        return Text(
                          _formatRupiah(double.tryParse(product["price"].toString())?.toInt() ?? 0),
                          style: TextStyle(fontSize: 26, color: Colors.orange[900], fontWeight: FontWeight.bold),
                        );
                      }
                      
                      final List<int> prices = variants.map<int>((v) => double.tryParse(v['price'].toString())?.toInt() ?? 0).toList();
                      final int minPrice = prices.reduce((a, b) => a < b ? a : b);
                      final int maxPrice = prices.reduce((a, b) => a > b ? a : b);

                      return Text(
                        minPrice == maxPrice ? _formatRupiah(minPrice) : "${_formatRupiah(minPrice)} - ${_formatRupiah(maxPrice)}",
                        style: TextStyle(fontSize: 24, color: Colors.orange[900], fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product["name"] ?? "Nama Produk",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black87, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if ((product['stock'] ?? 0) <= 0)
                        _buildInfoTag("Stok Habis", color: Colors.red)
                      else
                        _buildInfoTag("Stok: ${product['stock'] ?? 0}"),
                      const SizedBox(width: 8),
                      _buildInfoTag("${product['sold_count'] ?? 0} Terjual"),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          _isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorited ? Colors.red : Colors.grey,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFavorited = !_isFavorited;
                            FavoriteModel.toggleFavorite(widget.product['id']);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Store Info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(product['store']?['logo_url'] ?? "https://via.placeholder.com/40"),
                    child: product['store']?['logo_url'] == null ? Icon(Icons.storefront, color: Colors.orange[800]) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['store']?['name'] ?? "Toko Pakan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(product['store']?['address'] ?? "Yogyakarta", style: const TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => StorePage(store: product['store'])));
                    },
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orange), foregroundColor: Colors.orange),
                    child: const Text("Kunjungi Toko", style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Specifications
            if (specifications.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Spesifikasi Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 16),
                    ...specifications.map((spec) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(width: 100, child: Text(spec['name'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 13))),
                          Expanded(child: Text(spec['value'] ?? "", style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    )).toList(),
                  ],
                ),
              ),

            const SizedBox(height: 10),

            // Descriptions
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Deskripsi Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 16),
                  if (descriptions.isNotEmpty)
                    ...descriptions.map((desc) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (desc['title']?.isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, top: 8),
                            child: Text(desc['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        Text(desc['content'] ?? "", style: const TextStyle(color: Colors.black87, fontSize: 13, height: 1.6)),
                      ],
                    )).toList()
                  else
                    Text(product['description'] ?? "Produk berkualitas untuk hewan ternak Anda.", style: const TextStyle(fontSize: 13, height: 1.6)),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildShopeeBottomBar(context),
    );
  }

  void _showPurchaseBottomSheet(bool isDirectCheckout) {
    final product = widget.product;
    int quantity = 1;
    String? selectedVar;
    String? selectedPack;

    // Sinkronisasi dengan nama relasi di Laravel Backend
    final List allVariants = product['variants'] ?? [];
    // Shopee System: Jangan tampilkan jika hanya ada satu varian bernama 'Default'
    final List variants = allVariants.where((v) => v['name'] != 'Default').toList();
    
    // Cek kemungkinan kunci packing (snake_case atau camelCase)
    final List packingOptions = product['packing_options'] ?? product['packingOptions'] ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // Kalkulasi Harga Dinamis
            int currentUnitPrice = double.tryParse(product['price'].toString())?.toInt() ?? 0;
            
            // Jika varian dipilih, gunakan harga varian
            if (selectedVar != null) {
              final variantObj = variants.firstWhere((v) => v['name'] == selectedVar, orElse: () => null);
              if (variantObj != null) {
                currentUnitPrice = double.tryParse(variantObj['price'].toString())?.toInt() ?? 0;
              }
            }

            // Tambahkan harga packing jika ada
            if (selectedPack != null) {
              final packObj = packingOptions.firstWhere((p) => p['name'] == selectedPack, orElse: () => null);
              if (packObj != null) {
                currentUnitPrice += double.tryParse(packObj['extra_price'].toString())?.toInt() ?? 0;
              }
            }

            return Container(
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          (product['images']?.isNotEmpty ?? false) ? product['images'][0]['image_url'] : "https://via.placeholder.com/150",
                          width: 100, height: 100, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: Colors.grey[100], child: const Icon(Icons.image)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatRupiah(currentUnitPrice), 
                              style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 20)
                            ),
                            const SizedBox(height: 4),
                            Text("Stok: ${product['stock'] ?? 0}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            if (selectedVar != null || selectedPack != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Pilihan: ${selectedVar ?? ''}${selectedVar != null && selectedPack != null ? ', ' : ''}${selectedPack ?? ''}",
                                  style: TextStyle(color: Colors.orange[800], fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(height: 32),

                  // Tampilkan Variasi hanya jika ada varian selain 'Default'
                  if (variants.isNotEmpty) ...[
                    const Text("Variasi Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: variants.map<Widget>((v) {
                        bool isSelected = selectedVar == v['name'];
                        return _buildChoiceChip(v['name'], isSelected, () => setModalState(() => selectedVar = v['name']));
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Tampilkan Packing hanya jika ada
                  if (packingOptions.isNotEmpty) ...[
                    const Text("Opsi Packing", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: packingOptions.map<Widget>((p) {
                        bool isSelected = selectedPack == p['name'];
                        return _buildChoiceChip(p['name'], isSelected, () => setModalState(() => selectedPack = p['name']));
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Jumlah", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            _buildModernQtyBtn(Icons.remove, quantity > 1 ? () => setModalState(() => quantity--) : null),
                            SizedBox(width: 40, child: Text("$quantity", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))),
                            _buildModernQtyBtn(Icons.add, quantity < (product['stock'] ?? 100) ? () => setModalState(() => quantity++) : null),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () {
                        // Validasi tetap berjalan jika data ada
                        if (variants.isNotEmpty && selectedVar == null) {
                          NotificationHelper.show(context, "Silakan pilih variasi dahulu", isError: true);
                          return;
                        }
                        if (packingOptions.isNotEmpty && selectedPack == null) {
                          NotificationHelper.show(context, "Silakan pilih opsi packing", isError: true);
                          return;
                        }

                        Navigator.pop(context);
                        final Map<String, dynamic> finalProduct = Map<String, dynamic>.from(product);
                        finalProduct['selected_variation'] = selectedVar;
                        finalProduct['selected_packing'] = selectedPack;

                        if (isDirectCheckout) {
                          final directItem = Map<String, dynamic>.from(finalProduct)..['quantity'] = quantity;
                          Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutPage(directItems: [directItem]))).then((_) => setState(() {}));
                        } else {
                          setState(() => CartModel.addItem(finalProduct, quantity: quantity));
                          _showAddToCartFeedback(context);
                        }
                      },
                      child: Text(isDirectCheckout ? "BELI SEKARANG" : "MASUKKAN KERANJANG", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: isSelected ? Colors.orange[800]! : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.orange[800] : Colors.black87, fontSize: 12)),
      ),
    );
  }

  Widget _buildModernQtyBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32, height: 32, alignment: Alignment.center,
        child: Icon(icon, size: 16, color: onTap == null ? Colors.grey[300] : Colors.black87),
      ),
    );
  }

  Widget _buildSingleImage(String url) {
    return Image.network(url, width: double.infinity, height: 350, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildImageError());
  }

  Widget _buildImageSlider(List images) {
    return SizedBox(
      height: 350,
      child: PageView.builder(
        itemCount: images.length,
        onPageChanged: (index) => setState(() => _currentImageIndex = index),
        itemBuilder: (context, index) => Image.network(images[index]['image_url'], width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildImageError()),
      ),
    );
  }

  Widget _buildImageError() => Container(height: 350, color: Colors.grey[100], child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey));

  Widget _buildInfoTag(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color?.withOpacity(0.1) ?? Colors.grey[50], borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(color: color ?? Colors.grey, fontSize: 11)),
    );
  }

  Widget _buildShopeeBottomBar(BuildContext context) {
    final product = widget.product;
    bool isOutOfStock = (product['stock'] ?? 0) <= 0;
    return Container(
      height: 60,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          _buildBottomIcon(icon: Icons.chat_outlined, label: "Chat", onTap: () => NotificationHelper.show(context, "Fitur chat segera hadir!", isError: true)),
          Container(width: 1, height: 30, color: Colors.grey[200]),
          _buildBottomIcon(icon: Icons.add_shopping_cart_outlined, label: "Tambah", onTap: isOutOfStock ? null : () => _showPurchaseBottomSheet(false), color: isOutOfStock ? Colors.grey : Colors.orange[800]),
          Expanded(
            child: InkWell(
              onTap: isOutOfStock ? null : () => _showPurchaseBottomSheet(true),
              child: Container(
                color: isOutOfStock ? Colors.grey[400] : Colors.orange[800],
                alignment: Alignment.center,
                child: Text(isOutOfStock ? "STOK HABIS" : "BELI SEKARANG", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomIcon({required IconData icon, required String label, required VoidCallback? onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      child: Container(width: 70, alignment: Alignment.center, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: color ?? Colors.orange[800], size: 20), const SizedBox(height: 2), Text(label, style: TextStyle(color: color ?? Colors.orange[800], fontSize: 10))])),
    );
  }

  void _showAddToCartFeedback(BuildContext context) => NotificationHelper.show(context, "Berhasil masuk ke keranjang", isError: false);

  String _formatRupiah(int price) => "Rp${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}";
}
