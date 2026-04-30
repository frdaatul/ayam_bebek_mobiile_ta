import 'package:flutter/material.dart';
import 'dart:math';
import '../../models/cart_model.dart';
import '../../services/session_service.dart';
import '../../utils/notification_helper.dart';
import '../tracking/tracking_page.dart';
import 'success_page.dart';

class CheckoutPage extends StatefulWidget {
  final List<Map<String, dynamic>>? directItems;
  const CheckoutPage({super.key, this.directItems});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final addressController = TextEditingController();
  String selectedPayment = "Transfer Bank";

  // Penentuan Ongkir Otomatis Berdasarkan Volume (Jumlah Item)
  Map<String, dynamic> _calculateShipping(List items) {
    int totalQuantity = 0;
    for (var item in items) {
      totalQuantity += (item['quantity'] as int? ?? 1);
    }

    if (totalQuantity <= 5) {
      return {
        "type": "Reguler (Pesanan Kecil)",
        "cost": 12000,
        "icon": Icons.local_shipping,
        "color": Colors.green
      };
    } else {
      return {
        "type": "Cargo (Pesanan Besar/Banyak)",
        "cost": 45000,
        "icon": Icons.local_shipping_outlined,
        "color": Colors.blue
      };
    }
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill alamat dari profil user
    final user = Session.user ?? {};
    addressController.text = user['address'] ?? "";
  }

  int _calculateTotal() {
    if (widget.directItems != null) {
      int total = 0;
      for (var item in widget.directItems!) {
        int price = double.tryParse(item["price"].toString())?.toInt() ?? 0;
        total += price * (item["quantity"] as int);
      }
      return total;
    }
    return CartModel.getTotalPrice();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.directItems ?? CartModel.getItems();
    final total = _calculateTotal();
    final shipInfo = _calculateShipping(items);
    final int shippingCost = shipInfo['cost'];
    final user = Session.user ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Checkout",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Alamat Pengiriman
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.orange, size: 20),
                            const SizedBox(width: 8),
                            const Text("Alamat Pengiriman", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${user['name'] ?? 'User'} | ${user['phone'] ?? ''}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: addressController,
                          maxLines: null,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                          decoration: const InputDecoration(
                            hintText: "Masukkan alamat lengkap...",
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Daftar Produk
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.storefront, color: Colors.black87, size: 20),
                            const SizedBox(width: 8),
                            const Text("Pesanan Anda", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...items.map((item) => _buildProductItem(item)).toList(),
                      ],
                    ),
                  ),

                  // Opsi Pengiriman (OTOMATIS SESUAI KEBUTUHAN FUNGSIONAL)
                  _buildSectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(shipInfo['icon'], color: shipInfo['color'], size: 20),
                            const SizedBox(width: 8),
                            const Text("Metode Pengiriman", style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (shipInfo['color'] as Color).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: (shipInfo['color'] as Color).withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shipInfo['type'],
                                    style: TextStyle(color: shipInfo['color'], fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const Text("Berdasarkan volume pesanan", style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              Text(
                                _formatRupiah(shipInfo['cost']),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Metode Pembayaran
                  _buildSectionContainer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text("Metode Pembayaran"),
                          ],
                        ),
                        DropdownButton<String>(
                          value: selectedPayment,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          items: ["Transfer Bank", "E-Wallet", "COD"]
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => selectedPayment = val!),
                        ),
                      ],
                    ),
                  ),

                  // Rincian Pembayaran
                  _buildSectionContainer(
                    child: Column(
                      children: [
                        _buildSummaryRow("Subtotal Produk", total),
                        _buildSummaryRow("Subtotal Pengiriman", shippingCost),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              _formatRupiah(total + shippingCost),
                              style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Total Pembayaran", style: TextStyle(fontSize: 12)),
                      Text(
                        _formatRupiah(total + shippingCost),
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _handleConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: const Text("Buat Pesanan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      child: child,
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    int price = double.tryParse(item["price"].toString())?.toInt() ?? 0;
    String imageUrl = (item["images"] != null && item["images"].isNotEmpty) 
        ? item["images"][0]["image_url"] 
        : "https://via.placeholder.com/60";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item["name"] ?? "Produk", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                if (item['selected_variation'] != null || item['selected_packing'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      "${item['selected_variation'] ?? ''}${item['selected_variation'] != null && item['selected_packing'] != null ? ', ' : ''}${item['selected_packing'] ?? ''}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatRupiah(price), style: const TextStyle(fontSize: 13)),
                    Text("x${item['quantity'] ?? 1}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(_formatRupiah(value), style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _handleConfirmation() {
    if (addressController.text.isEmpty) {
      NotificationHelper.show(context, "Alamat tidak boleh kosong", isError: true);
      return;
    }

    // Simulasi Pengiriman ke API
    // Jika berhasil, bersihkan keranjang jika bukan beli langsung
    if (widget.directItems == null) {
      CartModel.clear();
    }

    // Generate Random Order ID untuk simulasi
    String orderId = "ORD-${Random().nextInt(90000) + 10000}";

    // Navigasi ke Halaman Sukses
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => SuccessPage(orderId: orderId)),
      (route) => false,
    );
  }

  String _formatRupiah(int price) {
    return "Rp${price.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}";
  }
}
