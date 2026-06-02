import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_theme.dart';
import '../../core/routes.dart';
import '../../core/utils.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../providers/task_provider.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _currentPosition;
  bool _isLoading = true;

  Task? _selectedTask;
  User? _selectedWorker;

  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();

  List<User> _nearbyWorkers = [];

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    try {
      final position = await _locationService.getCurrentPosition();
      _currentPosition = LatLng(position.latitude, position.longitude);

      // Load nearby workers
      _nearbyWorkers = await _userService.getNearbyWorkers(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _buildMarkers();
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition!, 14),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildMarkers() {
    final newMarkers = <Marker>{};

    // Current location marker
    if (_currentPosition != null) {
      newMarkers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Lokasi Saya'),
      ));
    }

    // Task markers (orange)
    final tasks = context.read<TaskProvider>().nearbyTasks;
    for (final task in tasks) {
      if (task.lat != null && task.lng != null) {
        newMarkers.add(Marker(
          markerId: MarkerId('task_${task.id}'),
          position: LatLng(task.lat!, task.lng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          onTap: () {
            setState(() {
              _selectedTask = task;
              _selectedWorker = null;
            });
          },
        ));
      }
    }

    // Worker markers (blue)
    for (final worker in _nearbyWorkers) {
      if (worker.lat != null && worker.lng != null) {
        newMarkers.add(Marker(
          markerId: MarkerId('worker_${worker.id}'),
          position: LatLng(worker.lat!, worker.lng!),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () {
            setState(() {
              _selectedWorker = worker;
              _selectedTask = null;
            });
          },
        ));
      }
    }

    if (mounted) setState(() => _markers.addAll(newMarkers));
  }

  void _centerOnCurrentLocation() async {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    } else {
      try {
        final position = await _locationService.getCurrentPosition(
            forceRefresh: true);
        final latLng = LatLng(position.latitude, position.longitude);
        setState(() => _currentPosition = latLng);
        _mapController?.animateCamera(
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
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _buildMarkers();
              _initMap();
            },
            tooltip: 'Perbarui',
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // ─── Map ──────────────────────────────────────────────────────────
          Consumer<TaskProvider>(
            builder: (_, taskProvider, __) {
              return GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_currentPosition != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(_currentPosition!, 14),
                    );
                  }
                },
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? const LatLng(-6.2088, 106.8456),
                  zoom: 13,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                onTap: (_) {
                  setState(() {
                    _selectedTask = null;
                    _selectedWorker = null;
                  });
                },
              );
            },
          ),

          // ─── Loading ──────────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            ),

          // ─── Legend ───────────────────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLegendItem(
                    color: AppTheme.accentOrange,
                    label: 'Tugas',
                  ),
                  const SizedBox(height: 4),
                  _buildLegendItem(
                    color: AppTheme.primaryBlue,
                    label: 'Pekerja',
                  ),
                ],
              ),
            ),
          ),

          // ─── Bottom Sheet: Task Detail ─────────────────────────────────
          if (_selectedTask != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildTaskBottomSheet(_selectedTask!),
            ),

          // ─── Bottom Sheet: Worker Detail ───────────────────────────────
          if (_selectedWorker != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildWorkerBottomSheet(_selectedWorker!),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'center_map',
            mini: true,
            onPressed: _centerOnCurrentLocation,
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.primaryBlue,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskBottomSheet(Task task) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getCategoryLabel(task.category ?? 'lainnya'),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _selectedTask = null),
                icon: const Icon(Icons.close, size: 20),
                style: IconButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(task.title, style: AppTheme.subtitle1, maxLines: 2),
          const SizedBox(height: 6),
          Text(
            formatBudgetRange(task.budgetMin, task.budgetMax),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentOrange,
            ),
          ),
          if (task.locationAddress != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.locationAddress!,
                      style: AppTheme.body2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.taskDetail,
                    arguments: task.id);
                setState(() => _selectedTask = null);
              },
              child: const Text('Lihat Detail'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerBottomSheet(User worker) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundImage: worker.avatarUrl != null
                ? CachedNetworkImageProvider(worker.avatarUrl!)
                : null,
            backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
            child: worker.avatarUrl == null
                ? Text(
                    worker.name.isNotEmpty ? worker.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(worker.name, style: AppTheme.subtitle1),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      '${worker.rating.toStringAsFixed(1)} (${worker.totalReviews})',
                      style: AppTheme.body2,
                    ),
                  ],
                ),
                if (worker.distanceKm != null)
                  Text(
                    formatDistance(worker.distanceKm),
                    style: AppTheme.caption,
                  ),
              ],
            ),
          ),

          // Close button
          IconButton(
            onPressed: () => setState(() => _selectedWorker = null),
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
    );
  }
}
