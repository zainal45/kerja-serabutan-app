import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/utils.dart';
import '../../providers/task_provider.dart';
import '../../services/location_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetMinController = TextEditingController();
  final _budgetMaxController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedCategory = 'bersih-bersih';
  DateTime? _scheduledAt;
  LatLng? _selectedLocation;
  GoogleMapController? _miniMapController;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _initCurrentLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    _addressController.dispose();
    _miniMapController?.dispose();
    super.dispose();
  }

  Future<void> _initCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _locationService.getAddressFromLatLng(
          position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _selectedLocation = latLng;
          _addressController.text = address;
        });
        _miniMapController?.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
    } catch (_) {}
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: 'Pilih Tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      locale: const Locale('id', 'ID'),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Pilih Waktu',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _getCurrentLocationForTask() async {
    try {
      final position = await _locationService.getCurrentPosition(
          forceRefresh: true);
      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _locationService.getAddressFromLatLng(
          position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedLocation = latLng;
        _addressController.text = address;
      });
      _miniMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 15),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat mengakses lokasi')),
        );
      }
    }
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate()) return;

    final budgetMin = double.tryParse(_budgetMinController.text) ?? 0;
    final budgetMax = double.tryParse(_budgetMaxController.text) ?? 0;

    if (budgetMin <= 0 || budgetMax <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget harus lebih dari 0'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (budgetMax < budgetMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Budget maksimum harus lebih besar dari minimum'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final task = await context.read<TaskProvider>().createTask(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          budgetMin: budgetMin,
          budgetMax: budgetMax,
          locationAddress: _addressController.text.trim(),
          lat: _selectedLocation?.latitude,
          lng: _selectedLocation?.longitude,
          scheduledAt: _scheduledAt,
        );

    if (!mounted) return;

    if (task != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil dibuat!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      final error =
          context.read<TaskProvider>().errorMessage ?? 'Gagal membuat tugas';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posting Tugas'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Title ──────────────────────────────────────────────────
              _buildSectionCard(
                title: 'Informasi Tugas',
                children: [
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Judul Tugas',
                      hintText: 'Contoh: Bersih-bersih rumah 2 lantai',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Judul wajib diisi';
                      }
                      if (v.trim().length < 10) {
                        return 'Judul minimal 10 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'Jelaskan detail pekerjaan yang dibutuhkan...',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Deskripsi wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Category
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: taskCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          getCategoryLabel(cat),
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => _selectedCategory = v ?? 'lainnya'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Budget ──────────────────────────────────────────────────
              _buildSectionCard(
                title: 'Anggaran',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimum (Rp)',
                            hintText: '50000',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Angka tidak valid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Maksimum (Rp)',
                            hintText: '200000',
                            prefixIcon: Icon(Icons.payments),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Wajib diisi';
                            }
                            if (double.tryParse(v) == null) {
                              return 'Angka tidak valid';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Location ────────────────────────────────────────────────
              _buildSectionCard(
                title: 'Lokasi',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Alamat',
                            hintText: 'Masukkan alamat lokasi tugas',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Alamat wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _getCurrentLocationForTask,
                        icon: const Icon(Icons.my_location),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Mini Map
                  Container(
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: AppTheme.divider),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _selectedLocation ??
                                  const LatLng(-6.2088, 106.8456),
                              zoom: 15,
                            ),
                            onMapCreated: (c) => _miniMapController = c,
                            markers: _selectedLocation != null
                                ? {
                                    Marker(
                                      markerId: const MarkerId('task_location'),
                                      position: _selectedLocation!,
                                      icon: BitmapDescriptor
                                          .defaultMarkerWithHue(
                                              BitmapDescriptor.hueOrange),
                                    ),
                                  }
                                : {},
                            onTap: (latLng) async {
                              final address =
                                  await _locationService.getAddressFromLatLng(
                                      latLng.latitude, latLng.longitude);
                              if (!mounted) return;
                              setState(() {
                                _selectedLocation = latLng;
                                _addressController.text = address;
                              });
                            },
                            zoomControlsEnabled: false,
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                          ),
                          if (_selectedLocation == null)
                            Container(
                              color: Colors.black26,
                              child: const Center(
                                child: Text(
                                  'Ketuk peta untuk memilih lokasi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Schedule ────────────────────────────────────────────────
              _buildSectionCard(
                title: 'Jadwal (Opsional)',
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined,
                        color: AppTheme.primaryBlue),
                    title: Text(
                      _scheduledAt != null
                          ? formatDateTime(_scheduledAt!)
                          : 'Pilih tanggal & waktu',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: _scheduledAt != null
                            ? AppTheme.textPrimary
                            : AppTheme.textHint,
                      ),
                    ),
                    trailing: _scheduledAt != null
                        ? IconButton(
                            icon: const Icon(Icons.close,
                                color: AppTheme.textSecondary),
                            onPressed: () =>
                                setState(() => _scheduledAt = null),
                          )
                        : null,
                    onTap: _pickSchedule,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Submit ──────────────────────────────────────────────────
              Consumer<TaskProvider>(
                builder: (_, taskProvider, __) {
                  return SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: taskProvider.isCreating ? null : _submitTask,
                      icon: taskProvider.isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.publish),
                      label: const Text('Posting Tugas'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
