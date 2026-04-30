import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/session_service.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List allOrders = [];
  bool isLoading = true;

  final List<String> _tabs = ["Semua", "Belum Bayar", "Dikemas", "Dikirim", "Selesai", "Dibatalkan"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final userId = Session.user?['id'];
      final response = await http.get(Uri.parse("http://192.168.22.39:8000/api/orders?user_id=$userId"));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          allOrders = data['data'];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoading = false; });
    }
  }

  List _getFilteredOrders(String status) {
    if (status == "Semua") return allOrders;
    
    // Mapping status Shopee ke status DB
    String dbStatus = status.toLowerCase();
    if (status == "Belum Bayar") dbStatus = "pending";
    if (status == "Dikemas") dbStatus = "processing";
    if (status == "Dikirim") dbStatus = "shipping";
    if (status == "Selesai") dbStatus = "completed";
    
    if (status == "Dibatalkan") {
      return allOrders.where((o) => o['status'] == 'cancelled' || o['status'] == 'refunded').toList();
    }

    return allOrders.where((o) => o['status'] == dbStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Pesanan Saya", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.orange[800],
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.orange[800],
          indicatorWeight: 3,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final filtered = _getFilteredOrders(tab);
                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildOrderCard(filtered[index]),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Belum ada pesanan", style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final items = order['order_items'] ?? [];
    final firstItem = items.isNotEmpty ? items[0] : null;
    final storeName = order['store']?['name'] ?? "Toko Pakan";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Toko
          Row(
            children: [
              const Icon(Icons.storefront, size: 18, color: Colors.black87),
              const SizedBox(width: 8),
              Text(storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              _buildStatusLabel(order['status']),
            ],
          ),
          const Divider(height: 24),
          
          // Detail Produk Pertama
          if (firstItem != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    _getProductImage(firstItem),
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey[100], width: 70, height: 70, child: const Icon(Icons.image)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem['product']?['name'] ?? "Produk",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Variasi: ${firstItem['product_variant']?['name'] ?? 'Default'}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("x${firstItem['quantity']}"),
                          Text(_formatRupiah(firstItem['unit_price'])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          
          if (items.length > 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text("Lihat ${items.length - 1} produk lainnya", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ),
            
          const Divider(height: 24),
          
          // Footer Harga & Tombol
          Row(
            children: [
              Text("${items.length} produk", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              const Text("Total Pesanan: ", style: TextStyle(fontSize: 12)),
              Text(
                _formatRupiah(order['total_amount']),
                style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton("Hubungi Penjual", Colors.black87, isPrimary: false),
              const SizedBox(width: 8),
              if (order['status'] == 'pending')
                _buildActionButton("Bayar Sekarang", Colors.orange[800]!, isPrimary: true),
              if (order['status'] == 'shipping')
                _buildActionButton("Pesanan Diterima", Colors.orange[800]!, isPrimary: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.transparent,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: isPrimary ? Colors.white : color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusLabel(String status) {
    Color color = Colors.orange[800]!;
    String label = status.toUpperCase();

    switch (status) {
      case 'pending':
        label = 'Belum Bayar';
        color = Colors.orange[800]!;
        break;
      case 'processing':
        label = 'Dikemas';
        color = Colors.orange[800]!;
        break;
      case 'shipping':
        label = 'Dikirim';
        color = Colors.blue;
        break;
      case 'completed':
        label = 'Selesai';
        color = Colors.green;
        break;
      case 'cancelled':
        label = 'Dibatalkan';
        color = Colors.red;
        break;
      case 'refunded':
        label = 'Refund';
        color = Colors.red;
        break;
    }

    return Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  String _getProductImage(dynamic item) {
    final images = item['product']?['images'] ?? [];
    if (images.isNotEmpty) return images[0]['image_url'];
    return "https://via.placeholder.com/100";
  }

  String _formatRupiah(dynamic price) {
    int p = double.tryParse(price.toString())?.toInt() ?? 0;
    return "Rp${p.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}";
  }
}
