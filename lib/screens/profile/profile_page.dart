import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../services/session_service.dart';
import '../../utils/notification_helper.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  // State variables
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Session.user ?? {};
    nameController = TextEditingController(text: user['name'] ?? "");
    emailController = TextEditingController(text: user['email'] ?? "");
    phoneController = TextEditingController(text: user['phone'] ?? "");
    addressController = TextEditingController(text: user['address'] ?? "");
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? selected = await _picker.pickImage(source: ImageSource.gallery);
    if (selected != null) {
      setState(() => _imageFile = File(selected.path));
    }
  }



  Future<void> _handleUpdate() async {
    final user = Session.user ?? {};

    bool isNameChanged = nameController.text.trim() != (user['name'] ?? "");
    bool isPhoneChanged = phoneController.text.trim() != (user['phone'] ?? "");
    bool isAddressChanged = addressController.text.trim() != (user['address'] ?? "");
    bool isImageChanged = _imageFile != null;

    if (!isNameChanged && !isPhoneChanged && !isAddressChanged && !isImageChanged) {
      NotificationHelper.show(context, "Tidak ada perubahan data yang dilakukan.");
      return;
    }

    setState(() => _isLoading = true);

    const String apiUrl = "http://192.168.22.39:8000/api/profile/update";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers.addAll({
        'Authorization': 'Bearer ${Session.token}',
        'Accept': 'application/json',
      });

      request.fields['name'] = nameController.text.trim();
      request.fields['phone'] = phoneController.text.trim();
      request.fields['address'] = addressController.text.trim();

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', _imageFile!.path));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Session.user = responseData['data']['user'];
        setState(() => _imageFile = null);

        NotificationHelper.show(context, responseData['message'] ?? "Profil berhasil diperbarui", isError: false);
      } else {
        if (responseData['errors'] != null) {
          List<String> allErrors = [];
          (responseData['errors'] as Map<String, dynamic>).forEach((key, value) {
            if (value is List) {
              allErrors.addAll(value.map((e) => e.toString()));
            } else {
              allErrors.add(value.toString());
            }
          });
          NotificationHelper.show(context, allErrors, isError: true);
        } else {
          NotificationHelper.show(context, responseData['message'] ?? "Gagal memperbarui profil.", isError: true);
        }
      }
    } catch (e) {
      NotificationHelper.show(context, "Gagal terhubung ke server. Periksa koneksi internet Anda.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.user ?? {};
    String? avatarUrl = user['avatar'];
    String fullAvatarUrl = avatarUrl != null ? "http://192.168.22.39:8000/storage/$avatarUrl" : "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profil Saya", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (avatarUrl != null ? NetworkImage(fullAvatarUrl) : null) as ImageProvider?,
                    child: _imageFile == null && avatarUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.orange)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildEditField(controller: nameController, label: "Nama Lengkap", icon: Icons.person_outline, isRequired: true),
            const SizedBox(height: 20),
            _buildEditField(controller: emailController, label: "Email", icon: Icons.email_outlined, enabled: false),
            const SizedBox(height: 20),
            _buildEditField(
              controller: phoneController,
              label: "Nomor HP",
              icon: Icons.phone_android_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              isRequired: true,
            ),
            const SizedBox(height: 20),
            _buildEditField(controller: addressController, label: "Alamat", icon: Icons.location_on_outlined, maxLines: 3, isRequired: true),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SIMPAN PERUBAHAN", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool isRequired = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            if (isRequired)
              const Text(" *", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: enabled ? Colors.grey[100] : Colors.grey[200], borderRadius: BorderRadius.circular(15)),
          child: TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              icon: Icon(icon, color: Colors.orange),
              border: InputBorder.none,
              hintText: "Masukkan $label",
              hintStyle: const TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
