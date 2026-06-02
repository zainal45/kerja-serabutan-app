import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../core/routes.dart';
import '../../core/utils.dart';
import '../../models/task.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/task_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadAllMyTasks();
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoadingReviews = true);
    try {
      _reviews = await _userService.getUserReviews(userId);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingReviews = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text(
            'Apakah kamu yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.login, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: NestedScrollView(
        headerSliverBuilder: (_, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await Navigator.pushNamed(context, AppRoutes.editProfile);
                  auth.refreshUser();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: _logout,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.primaryBlueDark, AppTheme.primaryBlue],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Avatar
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundImage: user.avatarUrl != null
                                ? CachedNetworkImageProvider(user.avatarUrl!)
                                : null,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            child: user.avatarUrl == null
                                ? Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Name
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Role badge
                      if (user.role != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getRoleLabel(user.role!),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),

                      // Rating
                      if (user.totalReviews > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            RatingBarIndicator(
                              rating: user.rating,
                              itemBuilder: (_, __) => const Icon(
                                  Icons.star,
                                  color: Colors.amber),
                              itemCount: 5,
                              itemSize: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${user.rating.toStringAsFixed(1)} (${user.totalReviews} ulasan)',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                color: AppTheme.primaryBlue,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  indicatorColor: AppTheme.accentOrange,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Tugas Saya'),
                    Tab(text: 'Ulasan'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // ─── Tugas Saya Tab ─────────────────────────────────────────────
            _TasksTab(),
            // ─── Ulasan Tab ─────────────────────────────────────────────────
            _ReviewsTab(reviews: _reviews, isLoading: _isLoadingReviews),
          ],
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'client':
        return 'Klien';
      case 'worker':
        return 'Pekerja';
      case 'both':
        return 'Klien & Pekerja';
      default:
        return role;
    }
  }
}

// ─── Tasks Tab ────────────────────────────────────────────────────────────────

class _TasksTab extends StatefulWidget {
  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTab;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _innerTab,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryBlue,
            labelStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Yang Saya Posting'),
              Tab(text: 'Yang Saya Lamar'),
            ],
          ),
        ),
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (_, taskProvider, __) {
              return TabBarView(
                controller: _innerTab,
                children: [
                  _TaskList(
                    tasks: taskProvider.myPostedTasks,
                    isLoading: taskProvider.isLoadingMine,
                    emptyMessage: 'Kamu belum pernah memposting tugas',
                    emptyIcon: Icons.post_add_outlined,
                  ),
                  _TaskList(
                    tasks: taskProvider.myAppliedTasks,
                    isLoading: taskProvider.isLoadingMine,
                    emptyMessage: 'Kamu belum pernah melamar tugas',
                    emptyIcon: Icons.send_outlined,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TaskList extends StatelessWidget {
  final List<Task> tasks;
  final bool isLoading;
  final String emptyMessage;
  final IconData emptyIcon;

  const _TaskList({
    required this.tasks,
    required this.isLoading,
    required this.emptyMessage,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 56, color: AppTheme.textHint),
            const SizedBox(height: 16),
            Text(emptyMessage, style: AppTheme.body2, textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: tasks.length,
      itemBuilder: (_, i) => TaskCard(task: tasks[i]),
    );
  }
}

// ─── Reviews Tab ──────────────────────────────────────────────────────────────

class _ReviewsTab extends StatelessWidget {
  final List<Review> reviews;
  final bool isLoading;

  const _ReviewsTab({required this.reviews, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryBlue),
      );
    }

    if (reviews.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border, size: 56, color: AppTheme.textHint),
            SizedBox(height: 16),
            Text('Belum ada ulasan', style: AppTheme.body2),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (_, i) => _ReviewCard(review: reviews[i]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review.reviewer;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: reviewer?.avatarUrl != null
                      ? CachedNetworkImageProvider(reviewer!.avatarUrl!)
                      : null,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
                  child: reviewer?.avatarUrl == null
                      ? Text(
                          reviewer?.name.isNotEmpty == true
                              ? reviewer!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewer?.name ?? 'Pengguna',
                        style: AppTheme.subtitle2,
                      ),
                      Text(
                        timeago.format(review.createdAt, locale: 'id'),
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                RatingBarIndicator(
                  rating: review.rating.toDouble(),
                  itemBuilder: (_, __) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 16,
                ),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.comment!, style: AppTheme.body2),
            ],
          ],
        ),
      ),
    );
  }
}
