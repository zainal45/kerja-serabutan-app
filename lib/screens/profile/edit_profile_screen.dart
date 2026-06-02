import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _skillInputController = TextEditingController();
  final _locationController = TextEditingController();

  final UserService _userService = UserService();
  final LocationService _locationService = LocationService();
  final ImagePicker _imagePicker = ImagePicker();

  String? _avatarPath;
  List<String> _skills = [];
  double? _lat;
  double? _lng;
  bool _isSaving = false;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    _nameController.text = user.name;
    _phoneController.text = user.phone ?? '';
    _bioController.text = user.bio ?? '';
    _locationController.text = user.locationName ?? '';
    _skills = List.from(user.skills);
    _lat = user.lat;
    _lng = user.lng;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _skillInputController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih Foto', style: AppTheme.subtitle1),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppTheme.primaryBlue),
              title: const Text('Kamera',
                  style: TextStyle(fontFamily: 'Poppins')),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppTheme.primaryBlue),
              title: const Text('Galeri',
                  style: TextStyle(fontFamily: 'Poppins')),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (image != null && mounted) {
        setState(() => _avatarPath = image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memilih foto')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition(
          forceRefresh: true);
      final address = await _locationService.getAddressFromLatLng(
          position.latitude, position.longitude);
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _locationController.text = address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isEmpty) return;
    if (_skills.contains(skill)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keahlian sudah ada')),
      );
      return;
    }
    if (_skills.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimum 10 keahlian')),
      );
      return;
    }
    setState(() {
      _skills.add(skill);
      _skillInputController.clear();
    });
  }

  void _removeSkill(String skill) {
    setState(() => _skills.remove(skill));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedUser = await _userService.updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        locationName: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        lat: _lat,
        lng: _lng,
        skills: _skills.isEmpty ? null : _skills,
        avatarPath: _avatarPath,
      );

      if (mounted) {
        context.read<AuthProvider>().updateCurrentUser(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Avatar ──────────────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 56,
                        backgroundColor:
                            AppTheme.primaryBlue.withOpacity(0.12),
                        backgroundImage: _avatarPath != null
                            ? null // Will show local file
                            : (user?.avatarUrl != null
                                ? CachedNetworkImageProvider(user!.avatarUrl!)
                                : null),
                        child: _avatarPath == null && user?.avatarUrl == null
                            ? Text(
                                user?.name.isNotEmpty == true
                                    ? user!.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryBlue,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Ketuk untuk mengubah foto',
                  style: AppTheme.caption,
                ),
              ),
              const SizedBox(height: 24),

              // ─── Personal Info ───────────────────────────────────────────
              _buildSection('Informasi Pribadi', [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    hintText: '08xxxxxxxxxx',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    hintText: 'Ceritakan tentang kamu dan pengalamanmu...',
                    alignLabelWithHint: true,
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // ─── Location ────────────────────────────────────────────────
              _buildSection('Lokasi', [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationController,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi',
                          hintText: 'Nama area atau kota',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isGettingLocation
                          ? null
                          : _getCurrentLocation,
                      icon: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primaryBlue.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 16),

              // ─── Skills ──────────────────────────────────────────────────
              _buildSection('Keahlian', [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _skillInputController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Tambah keahlian...',
                          prefixIcon: Icon(Icons.add_circle_outline),
                        ),
                        onSubmitted: (_) => _addSkill(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addSkill,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      child: const Text('Tambah'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_skills.isEmpty)
                  const Text(
                    'Tambahkan keahlian untuk menarik lebih banyak klien',
                    style: AppTheme.caption,
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _skills.map((skill) {
                      return Chip(
                        label: Text(skill,
                            style: const TextStyle(fontFamily: 'Poppins')),
                        onDeleted: () => _removeSkill(skill),
                        backgroundColor:
                            AppTheme.primaryBlue.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                        deleteIconColor: AppTheme.primaryBlue,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      );
                    }).toList(),
                  ),
              ]),
              const SizedBox(height: 32),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('Simpan Perubahan'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.subtitle2),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
