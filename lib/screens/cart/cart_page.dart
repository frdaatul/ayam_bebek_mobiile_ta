import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../../utils/notification_helper.dart';
import '../checkout/checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool isEditing = false;
  Set<int> selectedIndices = {};

  @override
  void initState() {
    super.initState();
    // Default: Semua tercentang seperti Shopee saat pertama buka
    final items = CartModel.getItems();
    for (int i = 0; i < items.length; i++) {
      selectedIndices.add(i);
    }
  }

  int _calculateSelectedTotal() {
    final cartItems = CartModel.getItems();
    int total = 0;
    for (int i = 0; i < cartItems.length; i++) {
      if (selectedIndices.contains(i)) {
        final item = cartItems[i];
        int price = double.tryParse(item["price"].toString())?.toInt() ?? 0;
        total += price * (item["quantity"] as int);
      }
    }
    return total;
  }

  void _toggleSelectAll() {
    setState(() {
      if (selectedIndices.length == CartModel.getItems().length) {
        selectedIndices.clear();
      } else {
        selectedIndices.clear();
        for (int i = 0; i < CartModel.getItems().length; i++) {
          selectedIndices.add(i);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = CartModel.getItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Keranjang Saya (${cartItems.length})",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => isEditing = !isEditing),
            child: Text(
              isEditing ? "Selesai" : "Ubah", 
              style: const TextStyle(color: Colors.orange)
            ),
          )
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _buildCartItem(item, index, cartItems);
                    },
                  ),
                ),
                _buildBottomSummary(context),
              ],
            ),
    );
  }

  Widget _buildCartItem(dynamic item, int index, List cartItems) {
    int price = double.tryParse(item["price"].toString())?.toInt() ?? 0;
    bool isSelected = selectedIndices.contains(index);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {
              setState(() {
                if (selectedIndices.contains(index)) {
                  selectedIndices.remove(index);
                } else {
                  selectedIndices.add(index);
                }
              });
            },
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(top: 25, right: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[400]!, 
                  width: 1.5
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? Colors.orange : Colors.transparent,
              ),
              child: isSelected 
                  ? const Icon(Icons.check, size: 16, color: Colors.white) 
                  : null,
            ),
          ),
          
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              (item["images"] != null && item["images"].isNotEmpty) 
                  ? item["images"][0]["image_url"] 
                  : "https://via.placeholder.com/80",
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"] ?? "Produk",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                if (item['selected_variation'] != null || item['selected_packing'] != null)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      "Variasi: ${item['selected_variation'] ?? ''}${item['selected_variation'] != null && item['selected_packing'] != null ? ', ' : ''}${item['selected_packing'] ?? ''}",
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _formatRupiah(price),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Quantity control
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          _buildQtyBtn(
                            Icons.remove, 
                            onTap: () => setState(() => CartModel.updateQuantity(index, -1))
                          ),
                          Container(
                            width: 40,
                            height: 25,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.symmetric(vertical: BorderSide(color: Colors.grey[300]!)),
                            ),
                            child: Text("${item['quantity'] ?? 1}", style: const TextStyle(fontSize: 12)),
                          ),
                          _buildQtyBtn(
                            Icons.add, 
                            onTap: () => setState(() => CartModel.addItem(item))
                          ),
                        ],
                      ),
                    ),
                    
                    // Delete Button (Hanya muncul saat mode Ubah aktif seperti Shopee)
                    if (isEditing)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                        onPressed: () => _showDeleteConfirmation(index, item["name"]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 25,
        height: 25,
        alignment: Alignment.center,
        child: Icon(icon, size: 14, color: Colors.grey[600]),
      ),
    );
  }

  void _showDeleteConfirmation(int index, String? name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus '${name ?? "produk ini"}' dari keranjang?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                CartModel.removeItem(index);
                selectedIndices.clear(); // Reset pilihan untuk menghindari error indeks
                // Opsional: Pilih semua lagi agar user tidak repot
                for (int i = 0; i < CartModel.getItems().length; i++) {
                  selectedIndices.add(i);
                }
              });
              Navigator.pop(context);
              NotificationHelper.show(context, "Produk berhasil dihapus", isError: false);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Wah, keranjang belanjaanmu kosong", style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("Belanja Sekarang", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context) {
    final cartItems = CartModel.getItems();
    bool isAllSelected = selectedIndices.length == cartItems.length && cartItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onTap: _toggleSelectAll,
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isAllSelected ? Colors.orange : Colors.grey[400]!, 
                        width: 1.5
                      ),
                      borderRadius: BorderRadius.circular(4),
                      color: isAllSelected ? Colors.orange : Colors.transparent,
                    ),
                    child: isAllSelected 
                        ? const Icon(Icons.check, size: 16, color: Colors.white) 
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Text("Semua", style: TextStyle(fontSize: 13, color: Colors.black87)),
                ],
              ),
            ),
            const Spacer(),
            if (!isEditing)
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text("Total ", style: TextStyle(fontSize: 13)),
                      Text(
                        _formatRupiah(_calculateSelectedTotal()),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(width: 12),
            SizedBox(
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  if (selectedIndices.isEmpty) {
                    NotificationHelper.show(context, "Pilih minimal satu produk", isError: true);
                    return;
                  }

                  if (isEditing) {
                    // Bulk Delete
                    _showBulkDeleteConfirmation();
                  } else {
                    // Checkout Selected Items
                    List<Map<String, dynamic>> selectedItems = [];
                    for (int index in selectedIndices) {
                      selectedItems.add(cartItems[index]);
                    }
                    Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => CheckoutPage(directItems: selectedItems))
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing ? Colors.red : Colors.orange[800],
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? "Hapus (${selectedIndices.length})" : "Checkout", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Produk", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text("Apakah Anda yakin ingin menghapus ${selectedIndices.length} produk terpilih?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                // Hapus dari yang indeks terbesar agar tidak merubah indeks yang akan dihapus selanjutnya
                List<int> sortedIndices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
                for (int index in sortedIndices) {
                  CartModel.removeItem(index);
                }
                selectedIndices.clear();
                isEditing = false;
              });
              Navigator.pop(context);
              NotificationHelper.show(context, "Produk berhasil dihapus", isError: false);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int price) {
    return "Rp${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}";
  }
}