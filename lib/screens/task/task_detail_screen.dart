import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../core/app_theme.dart';
import '../../core/routes.dart';
import '../../core/utils.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/task_service.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final TaskService _taskService = TaskService();

  Task? _task;
  List<TaskApplication> _applications = [];
  bool _isLoading = true;
  bool _isApplying = false;
  bool _isLoadingApplications = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    setState(() => _isLoading = true);
    try {
      final task = await _taskService.getTask(widget.taskId);
      if (mounted) setState(() => _task = task);

      // If I am the client, load applications
      final currentUser = context.read<AuthProvider>().currentUser;
      if (currentUser != null && task.clientId == currentUser.id) {
        _loadApplications();
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal memuat detail tugas');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoadingApplications = true);
    try {
      _applications =
          await _taskService.getTaskApplications(widget.taskId);
      if (mounted) setState(() {});
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingApplications = false);
    }
  }

  Future<void> _applyToTask() async {
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null || _task == null) return;

    // Show apply dialog
    final result = await _showApplyDialog();
    if (result == null) return;

    setState(() => _isApplying = true);
    try {
      await _taskService.applyToTask(
        widget.taskId,
        proposedPrice: result['price'] as double,
        message: result['message'] as String?,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lamaran berhasil dikirim!'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadTask();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('ApiException(', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<Map<String, dynamic>?> _showApplyDialog() async {
    final priceController = TextEditingController();
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lamar Tugas'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga yang Ditawarkan (Rp)',
                  hintText: 'Contoh: 150000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Harga wajib diisi';
                  final price = double.tryParse(v);
                  if (price == null || price <= 0) return 'Harga tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Pesan (opsional)',
                  hintText: 'Jelaskan pengalaman atau keahlian kamu...',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, {
                  'price': double.parse(priceController.text),
                  'message': messageController.text.isEmpty
                      ? null
                      : messageController.text,
                });
              }
            },
            child: const Text('Kirim Lamaran'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptWorker(String workerId) async {
    try {
      final updatedTask =
          await _taskService.acceptWorker(widget.taskId, workerId);
      if (mounted) {
        setState(() => _task = updatedTask);
        context.read<TaskProvider>().updateTaskInList(updatedTask);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pekerja berhasil diterima!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _openChat() async {
    if (_task == null) return;
    final currentUser = context.read<AuthProvider>().currentUser;
    if (currentUser == null) return;

    final isClient = currentUser.id == _task!.clientId;
    final otherUserId = isClient
        ? (_task!.worker?.id ?? '')
        : _task!.clientId;

    if (otherUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengguna tidak ditemukan')),
      );
      return;
    }

    final chatProvider = context.read<ChatProvider>();
    final room = await chatProvider.createRoom(_task!.id, otherUserId);

    if (!mounted) return;
    if (room != null) {
      Navigator.pushNamed(
        context,
        AppRoutes.chatRoom,
        arguments: {
          'roomId': room.id,
          'taskTitle': _task!.title,
          'otherUserName': isClient
              ? (_task!.worker?.name ?? 'Pekerja')
              : (_task!.client?.name ?? 'Klien'),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null || _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tugas')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: AppTheme.textHint),
              const SizedBox(height: 16),
              Text(_errorMessage ?? 'Tugas tidak ditemukan',
                  style: AppTheme.subtitle2),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _loadTask, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final task = _task!;
    final currentUser = context.watch<AuthProvider>().currentUser;
    final isMyTask = currentUser?.id == task.clientId;
    final isWorker = currentUser != null && !isMyTask;
    final canApply = isWorker && task.isOpen;

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
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
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCategoryBadge(task),
                        const SizedBox(height: 10),
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Status + Budget ─────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Anggaran', style: AppTheme.caption),
                            const SizedBox(height: 4),
                            Text(
                              formatBudgetRange(
                                  task.budgetMin, task.budgetMax),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(task.status),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ─── Description ─────────────────────────────────────────────
                if (task.description != null)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deskripsi', style: AppTheme.subtitle2),
                        const SizedBox(height: 8),
                        Text(task.description!, style: AppTheme.body1),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                // ─── Info Grid ────────────────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Tugas', style: AppTheme.subtitle2),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Lokasi',
                        value: task.locationAddress ?? 'Tidak ditentukan',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.schedule,
                        label: 'Diposting',
                        value: timeago.format(task.createdAt, locale: 'id'),
                      ),
                      if (task.scheduledAt != null) ...[(
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Dijadwalkan',
                          value: formatDateTime(task.scheduledAt!),
                        ),
                      ],
                      if (task.distanceKm != null) ...[(
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          icon: Icons.near_me_outlined,
                          label: 'Jarak',
                          value: formatDistance(task.distanceKm),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Client Info ──────────────────────────────────────────────
                if (task.client != null)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Diposting oleh', style: AppTheme.subtitle2),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildAvatar(task.client!.name,
                                task.client!.avatarUrl, 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(task.client!.name,
                                      style: AppTheme.subtitle2),
                                  if (task.client!.totalReviews > 0)
                                    Row(
                                      children: [
                                        RatingBarIndicator(
                                          rating: task.client!.rating,
                                          itemBuilder: (_, __) => const Icon(
                                              Icons.star,
                                              color: Colors.amber),
                                          itemCount: 5,
                                          itemSize: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${task.client!.totalReviews})',
                                          style: AppTheme.caption,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),

                // ─── Applicants (for client) ───────────────────────────────
                if (isMyTask && task.isOpen)
                  _buildApplicationsSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ─── Bottom Action Bar ─────────────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(task, isMyTask, canApply),
    );
  }

  Widget _buildApplicationsSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Pelamar', style: AppTheme.subtitle2),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_applications.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingApplications)
            const Center(child: CircularProgressIndicator())
          else if (_applications.isEmpty)
            const Text('Belum ada pelamar', style: AppTheme.body2)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _applications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 16),
              itemBuilder: (_, i) {
                final app = _applications[i];
                final worker = app.worker;
                return Row(
                  children: [
                    _buildAvatar(
                        worker?.name ?? 'P', worker?.avatarUrl, 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(worker?.name ?? 'Pekerja',
                              style: AppTheme.subtitle2),
                          Text(
                            formatRupiah(app.proposedPrice),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                          if (app.message != null && app.message!.isNotEmpty)
                            Text(app.message!,
                                style: AppTheme.body2,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: app.status == 'pending'
                          ? () => _acceptWorker(app.workerId)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        app.status == 'accepted' ? 'Diterima' : 'Terima',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget? _buildBottomBar(Task task, bool isMyTask, bool canApply) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (!isMyTask)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Chat'),
                ),
              ),
            if (!isMyTask && canApply) const SizedBox(width: 12),
            if (canApply)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isApplying ? null : _applyToTask,
                  icon: _isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Lamar Tugas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                  ),
                ),
              ),
            if (isMyTask && task.isInProgress)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final updated =
                        await _taskService.completeTask(task.id);
                    if (mounted) {
                      setState(() => _task = updated);
                      context
                          .read<TaskProvider>()
                          .updateTaskInList(updated);
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Tandai Selesai'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.caption),
            const SizedBox(height: 2),
            SizedBox(
              width: MediaQuery.of(context).size.width - 80,
              child: Text(value, style: AppTheme.body2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryBadge(Task task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        getCategoryLabel(task.category ?? 'lainnya'),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'open':
        color = AppTheme.statusOpen;
        break;
      case 'negotiating':
        color = AppTheme.statusNegotiating;
        break;
      case 'in_progress':
        color = AppTheme.statusInProgress;
        break;
      case 'completed':
        color = AppTheme.statusCompleted;
        break;
      default:
        color = AppTheme.statusCancelled;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        getStatusLabel(status),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildAvatar(String name, String? avatarUrl, double radius) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: CachedNetworkImageProvider(avatarUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.primaryBlue.withOpacity(0.12),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }
}
