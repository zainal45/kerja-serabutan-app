import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/chat_provider.dart';
import '../../core/app_theme.dart';
import '../../core/routes.dart';
import '../../services/location_service.dart';
import '../../widgets/task_card.dart';
import '../map/map_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _BerandaTab(),
    MapScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().setupSocketListeners();
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();
      if (mounted) {
        context.read<TaskProvider>().loadNearbyTasks(
              lat: position.latitude,
              lng: position.longitude,
            );
      }
    } catch (_) {
      // Load without location
      if (mounted) context.read<TaskProvider>().loadNearbyTasks();
    }
    if (mounted) {
      context.read<ChatProvider>().loadRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (_, chatProvider, __) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Beranda',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.map_outlined),
                activeIcon: Icon(Icons.map),
                label: 'Peta',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: chatProvider.totalUnread > 0,
                  label: Text('${chatProvider.totalUnread}'),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                activeIcon: Badge(
                  isLabelVisible: chatProvider.totalUnread > 0,
                  label: Text('${chatProvider.totalUnread}'),
                  child: const Icon(Icons.chat_bubble),
                ),
                label: 'Chat',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Beranda Tab ──────────────────────────────────────────────────────────────

class _BerandaTab extends StatefulWidget {
  const _BerandaTab();

  @override
  State<_BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<_BerandaTab> {
  String? _selectedCategory;
  final _scrollController = ScrollController();

  static const List<Map<String, dynamic>> _categories = [
    {'key': null, 'label': 'Semua', 'icon': Icons.apps},
    {
      'key': 'bersih-bersih',
      'label': 'Bersih-bersih',
      'icon': Icons.cleaning_services_outlined
    },
    {
      'key': 'pindahan',
      'label': 'Pindahan',
      'icon': Icons.local_shipping_outlined
    },
    {'key': 'servis', 'label': 'Servis', 'icon': Icons.build_outlined},
    {'key': 'tukang', 'label': 'Tukang', 'icon': Icons.handyman_outlined},
    {
      'key': 'kurir',
      'label': 'Kurir',
      'icon': Icons.delivery_dining_outlined
    },
    {'key': 'lainnya', 'label': 'Lainnya', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<TaskProvider>().loadMoreTasks();
    }
  }

  void _selectCategory(String? category) {
    setState(() => _selectedCategory = category);
    context.read<TaskProvider>().setFilter(category: category);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: () => context.read<TaskProvider>().refreshTasks(),
        color: AppTheme.primaryBlue,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ─── App Bar ────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryBlue,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlueDark,
                        AppTheme.primaryBlue,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Halo, ${user?.name.split(' ').first ?? 'Pengguna'}!',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Temukan pekerjaan di sekitarmu',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.createTask),
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add, color: Colors.white),
                                tooltip: 'Posting Tugas',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(
                  height: 0,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),

            // ─── Category Chips ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: AppTheme.primaryBlue,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundGrey,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          final isSelected =
                              _selectedCategory == cat['key'];
                          return GestureDetector(
                            onTap: () =>
                                _selectCategory(cat['key'] as String?),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryBlue
                                      : AppTheme.divider,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    cat['icon'] as IconData,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    cat['label'] as String,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── Section Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Tugas Terdekat', style: AppTheme.heading3),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.taskList),
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Task List ───────────────────────────────────────────────────
            Consumer<TaskProvider>(
              builder: (_, taskProvider, __) {
                if (taskProvider.isLoadingNearby &&
                    taskProvider.nearbyTasks.isEmpty) {
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildShimmerCard(),
                      childCount: 5,
                    ),
                  );
                }

                if (taskProvider.nearbyTasks.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.work_off_outlined,
                            size: 64,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada tugas di sekitarmu',
                            style: AppTheme.subtitle2,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Coba ubah radius pencarian atau kategori',
                            style: AppTheme.body2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      if (i == taskProvider.nearbyTasks.length) {
                        return taskProvider.hasMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryBlue,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : const SizedBox(height: 80);
                      }
                      return TaskCard(task: taskProvider.nearbyTasks[i]);
                    },
                    childCount: taskProvider.nearbyTasks.length + 1,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createTask),
        icon: const Icon(Icons.add),
        label: const Text(
          'Posting Tugas',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.accentOrange,
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _shimmer(width: 80, height: 24, radius: 20),
                const Spacer(),
                _shimmer(width: 60, height: 24, radius: 20),
              ],
            ),
            const SizedBox(height: 12),
            _shimmer(width: double.infinity, height: 16, radius: 4),
            const SizedBox(height: 8),
            _shimmer(width: 200, height: 16, radius: 4),
            const SizedBox(height: 12),
            _shimmer(width: 150, height: 14, radius: 4),
          ],
        ),
      ),
    );
  }

  Widget _shimmer({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
