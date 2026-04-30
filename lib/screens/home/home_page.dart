import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../product/product_page.dart';
import '../scan/scan_page.dart';
import '../order/order_page.dart';
import '../profile/profile_page.dart';
import '../login/login_page.dart';
import '../product/product_detail_page.dart';
import '../../models/favorite_model.dart';
import '../../services/session_service.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Mendapatkan daftar menu berdasarkan role
  List<Map<String, dynamic>> _getMenuItems() {
    final role = Session.user?['role']?.toString().toLowerCase();
    
    if (role == 'admin') {
      return [
        {
          'page': const ScanPage(),
          'label': 'Scan',
          'icon': Icons.qr_code_scanner_rounded,
        },
        {
          'page': const _LogoutPlaceholder(), // View khusus untuk logout
          'label': 'Keluar',
          'icon': Icons.logout_rounded,
        },
      ];
    } else {
      // Menu untuk Customer
      return [
        {
          'page': const _BerandaView(),
          'label': 'Beranda',
          'icon': Icons.home_rounded,
        },
        {
          'page': const ProductPage(),
          'label': 'Katalog',
          'icon': Icons.storefront_rounded,
        },
        {
          'page': const OrderPage(),
          'label': 'Pesanan',
          'icon': Icons.shopping_bag_rounded,
        },
      ];
    }
  }

  void _onItemTapped(int index) {
    final menuItems = _getMenuItems();
    // Jika admin klik 'Keluar' (index 1)
    if (Session.user?['role'] == 'admin' && index == 1) {
       // Logout ditangani di _LogoutPlaceholder atau langsung di sini
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems();
    
    return Scaffold(
      body: menuItems[_selectedIndex]['page'],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: _onItemTapped,
          items: menuItems.map((item) {
            return BottomNavigationBarItem(
              icon: Icon(item['icon']),
              label: item['label'],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Placeholder untuk proses logout Admin via Bottom Bar
class _LogoutPlaceholder extends StatefulWidget {
  const _LogoutPlaceholder();

  @override
  State<_LogoutPlaceholder> createState() => _LogoutPlaceholderState();
}

class _LogoutPlaceholderState extends State<_LogoutPlaceholder> {
  @override
  void initState() {
    super.initState();
    // Jalankan logout otomatis saat masuk ke tab ini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLogout(context);
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      await http.post(
        Uri.parse("http://192.168.22.39:8000/api/logout"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${Session.token}',
        },
      );
    } catch (e) {}

    if (mounted) {
      Session.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
  }
}

// ==========================================
// TAMPILAN TAB 1: BERANDA
// ==========================================
class _BerandaView extends StatefulWidget {
  const _BerandaView();

  @override
  State<_BerandaView> createState() => _BerandaViewState();
}

class _BerandaViewState extends State<_BerandaView> {
  List favoriteProducts = [];
  bool isLoadingFav = true;
  Map<String, int> orderCounts = {"pending": 0, "processing": 0, "shipping": 0};

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    try {
      final userId = Session.user?['id'];
      // 1. Fetch Orders for Status Counts
      final orderRes = await http.get(Uri.parse("http://192.168.22.39:8000/api/orders?user_id=$userId"));
      if (orderRes.statusCode == 200) {
        final orders = json.decode(orderRes.body)['data'] as List;
        if (!mounted) return;
        setState(() {
          orderCounts["pending"] = orders.where((o) => o['status'] == 'pending').length;
          orderCounts["processing"] = orders.where((o) => o['status'] == 'processing').length;
          orderCounts["shipping"] = orders.where((o) => o['status'] == 'shipping').length;
        });
      }

      // 2. Fetch All Products and filter by Favorites
      final prodRes = await http.get(Uri.parse("http://192.168.22.39:8000/api/products"));
      if (prodRes.statusCode == 200) {
        final allProds = json.decode(prodRes.body)['data'] as List;
        if (!mounted) return;
        setState(() {
          favoriteProducts = allProds.where((p) => FavoriteModel.isFavorited(p['id'])).toList();
          isLoadingFav = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { isLoadingFav = false; });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );
    try {
      await http.post(
        Uri.parse("http://192.168.22.39:8000/api/logout"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${Session.token}',
        },
      );
    } catch (e) {}
    if (mounted) {
      Navigator.pop(context);
      Session.logout();
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
    }
  }

  String _formatRupiah(dynamic price) {
    int val = double.tryParse(price.toString())?.toInt() ?? 0;
    return "Rp ${val.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.orange[800],
        elevation: 0,
        title: const Text("Beranda", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.white),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Promo Visual (Persisten)
            _buildBanner(),

            const SizedBox(height: 16),

            // SECTION: PELACAKAN PESANAN (Fokus Penjualan & Pengiriman)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Pesanan Saya", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.findAncestorStateOfType<_HomePageState>()?._onItemTapped(2),
                          child: Text("Lihat Riwayat >", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatusItem(Icons.wallet, "Belum Bayar", orderCounts["pending"]!),
                        _buildStatusItem(Icons.inventory_2, "Dikemas", orderCounts["processing"]!),
                        _buildStatusItem(Icons.local_shipping, "Dikirim", orderCounts["shipping"]!),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // SECTION: PRODUK FAVORIT ANDA (Data Asli)
            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text("Favorit Saya", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            if (isLoadingFav)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.orange)))
            else if (favoriteProducts.isEmpty)
              _buildEmptyFav()
            else
              SizedBox(
                height: 210,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: favoriteProducts.length,
                  itemBuilder: (context, index) => _buildFavoriteCard(favoriteProducts[index]),
                ),
              ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Stack(
      children: [
        Container(height: 60, color: Colors.orange[800]),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.orange[700]!, Colors.orange[400]!]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Solusi Pakan Ternak", style: TextStyle(color: Colors.white, fontSize: 12)),
                  Text("Pesan Mudah,\nPengiriman Cepat", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusItem(IconData icon, String label, int count) {
    return Column(
      children: [
        Stack(
          children: [
            Icon(icon, color: Colors.orange[800], size: 28),
            if (count > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black87)),
      ],
    );
  }

  Widget _buildFavoriteCard(dynamic product) {
    String imageUrl = (product['images'] != null && product['images'].isNotEmpty) 
        ? product['images'][0]['image_url'] 
        : "https://via.placeholder.com/150";
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailPage(product: product))),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: Colors.grey[200]!)
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl, 
                    fit: BoxFit.contain, // Menggunakan contain agar tidak terpotong
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? "Produk", 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRupiah(product['price']), 
                    style: TextStyle(color: Colors.orange[900], fontSize: 13, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: const Column(
        children: [
          Icon(Icons.favorite_border, color: Colors.grey, size: 40),
          SizedBox(height: 8),
          Text("Belum ada produk favorit", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}


