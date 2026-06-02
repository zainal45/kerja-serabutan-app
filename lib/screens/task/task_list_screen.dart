import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../core/utils.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _scrollController = ScrollController();
  String? _selectedCategory;
  String? _selectedStatus;

  static const _statuses = [
    {'value': null, 'label': 'Semua Status'},
    {'value': 'open', 'label': 'Tersedia'},
    {'value': 'negotiating', 'label': 'Negosiasi'},
    {'value': 'in_progress', 'label': 'Dikerjakan'},
    {'value': 'completed', 'label': 'Selesai'},
  ];

  static const _categories = [
    {'value': null, 'label': 'Semua Kategori'},
    {'value': 'bersih-bersih', 'label': 'Bersih-bersih'},
    {'value': 'pindahan', 'label': 'Pindahan'},
    {'value': 'servis', 'label': 'Servis'},
    {'value': 'tukang', 'label': 'Tukang'},
    {'value': 'kurir', 'label': 'Kurir'},
    {'value': 'lainnya', 'label': 'Lainnya'},
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

  void _applyFilter() {
    context.read<TaskProvider>().setFilter(
          category: _selectedCategory,
          status: _selectedStatus,
        );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Filter Tugas', style: AppTheme.heading3),
                  const SizedBox(height: 20),

                  // Category filter
                  const Text('Kategori', style: AppTheme.subtitle2),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      final isSelected = _selectedCategory == c['value'];
                      return GestureDetector(
                        onTap: () => setSheetState(
                            () => _selectedCategory = c['value'] as String?),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Text(
                            c['label'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Status filter
                  const Text('Status', style: AppTheme.subtitle2),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _statuses.map((s) {
                      final isSelected = _selectedStatus == s['value'];
                      return GestureDetector(
                        onTap: () => setSheetState(
                            () => _selectedStatus = s['value'] as String?),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryBlue
                                : AppTheme.backgroundGrey,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Text(
                            s['label'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              _selectedCategory = null;
                              _selectedStatus = null;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {});
                            _applyFilter();
                          },
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                      height: MediaQuery.of(context).viewInsets.bottom + 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semua Tugas'),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedCategory != null || _selectedStatus != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.accentOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (_, taskProvider, __) {
          // Active filter chips
          final hasFilter =
              _selectedCategory != null || _selectedStatus != null;

          return RefreshIndicator(
            onRefresh: () => taskProvider.refreshTasks(),
            color: AppTheme.primaryBlue,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Active filters display
                if (hasFilter)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Wrap(
                        spacing: 8,
                        children: [
                          if (_selectedCategory != null)
                            Chip(
                              label: Text(getCategoryLabel(_selectedCategory!)),
                              onDeleted: () {
                                setState(() => _selectedCategory = null);
                                _applyFilter();
                              },
                              backgroundColor:
                                  AppTheme.primaryBlue.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontFamily: 'Poppins',
                                fontSize: 12,
                              ),
                              deleteIconColor: AppTheme.primaryBlue,
                            ),
                          if (_selectedStatus != null)
                            Chip(
                              label: Text(getStatusLabel(_selectedStatus!)),
                              onDeleted: () {
                                setState(() => _selectedStatus = null);
                                _applyFilter();
                              },
                              backgroundColor:
                                  AppTheme.primaryBlue.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: AppTheme.primaryBlue,
                                fontFamily: 'Poppins',
                                fontSize: 12,
                              ),
                              deleteIconColor: AppTheme.primaryBlue,
                            ),
                        ],
                      ),
                    ),
                  ),

                // Loading state
                if (taskProvider.isLoadingNearby &&
                    taskProvider.nearbyTasks.isEmpty)
                  SliverFillRemaining(
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryBlue),
                    ),
                  )
                else if (taskProvider.nearbyTasks.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.work_off_outlined,
                              size: 64, color: AppTheme.textHint),
                          const SizedBox(height: 16),
                          const Text('Tidak ada tugas ditemukan',
                              style: AppTheme.subtitle2),
                          const SizedBox(height: 8),
                          const Text('Coba ubah filter pencarian',
                              style: AppTheme.body2),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedCategory = null;
                                _selectedStatus = null;
                              });
                              _applyFilter();
                            },
                            child: const Text('Hapus Filter'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
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
                              : const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Center(
                                    child: Text(
                                      'Tidak ada tugas lagi',
                                      style: AppTheme.body2,
                                    ),
                                  ),
                                );
                        }
                        return TaskCard(task: taskProvider.nearbyTasks[i]);
                      },
                      childCount: taskProvider.nearbyTasks.length + 1,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
