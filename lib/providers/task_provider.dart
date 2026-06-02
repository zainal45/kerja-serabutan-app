import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import '../services/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> _nearbyTasks = [];
  List<Task> _myPostedTasks = [];
  List<Task> _myAppliedTasks = [];

  bool _isLoadingNearby = false;
  bool _isLoadingMine = false;
  bool _isCreating = false;
  bool _hasMore = true;
  int _currentPage = 1;

  double? _lastLat;
  double? _lastLng;
  String? _activeCategory;
  String? _activeStatus;

  String? _errorMessage;

  // ─── Getters ─────────────────────────────────────────────────────────────────

  List<Task> get nearbyTasks => _nearbyTasks;
  List<Task> get myPostedTasks => _myPostedTasks;
  List<Task> get myAppliedTasks => _myAppliedTasks;
  bool get isLoadingNearby => _isLoadingNearby;
  bool get isLoadingMine => _isLoadingMine;
  bool get isCreating => _isCreating;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  String? get activeCategory => _activeCategory;
  String? get activeStatus => _activeStatus;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─── Nearby Tasks ─────────────────────────────────────────────────────────────

  Future<void> loadNearbyTasks({
    double? lat,
    double? lng,
    String? category,
    String? status,
    bool reset = true,
  }) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _nearbyTasks = [];
    }

    if (!_hasMore) return;
    if (_isLoadingNearby) return;

    _lastLat = lat ?? _lastLat;
    _lastLng = lng ?? _lastLng;
    _activeCategory = category;
    _activeStatus = status;

    _isLoadingNearby = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final tasks = await _taskService.getNearbyTasks(
        lat: _lastLat,
        lng: _lastLng,
        category: _activeCategory,
        status: _activeStatus,
        page: _currentPage,
      );

      if (reset) {
        _nearbyTasks = tasks;
      } else {
        _nearbyTasks = [..._nearbyTasks, ...tasks];
      }

      _hasMore = tasks.length >= 20;
      if (tasks.isNotEmpty) _currentPage++;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Gagal memuat tugas';
    } finally {
      _isLoadingNearby = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreTasks() async {
    if (!_hasMore || _isLoadingNearby) return;
    await loadNearbyTasks(
      lat: _lastLat,
      lng: _lastLng,
      category: _activeCategory,
      status: _activeStatus,
      reset: false,
    );
  }

  Future<void> refreshTasks() async {
    await loadNearbyTasks(
      lat: _lastLat,
      lng: _lastLng,
      category: _activeCategory,
      status: _activeStatus,
      reset: true,
    );
  }

  void setFilter({String? category, String? status}) {
    _activeCategory = category;
    _activeStatus = status;
    loadNearbyTasks(reset: true);
  }

  // ─── My Tasks ─────────────────────────────────────────────────────────────────

  Future<void> loadMyPostedTasks() async {
    _isLoadingMine = true;
    notifyListeners();
    try {
      _myPostedTasks = await _taskService.getMyPostedTasks();
    } catch (e) {
      _errorMessage = 'Gagal memuat tugas yang diposting';
    } finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  Future<void> loadMyAppliedTasks() async {
    _isLoadingMine = true;
    notifyListeners();
    try {
      _myAppliedTasks = await _taskService.getMyAppliedTasks();
    } catch (e) {
      _errorMessage = 'Gagal memuat tugas yang dilamar';
    } finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  Future<void> loadAllMyTasks() async {
    _isLoadingMine = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _taskService.getMyPostedTasks(),
        _taskService.getMyAppliedTasks(),
      ]);
      _myPostedTasks = results[0];
      _myAppliedTasks = results[1];
    } catch (e) {
      _errorMessage = 'Gagal memuat tugas';
    } finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  // ─── Create Task ─────────────────────────────────────────────────────────────

  Future<Task?> createTask({
    required String title,
    required String description,
    required String category,
    required double budgetMin,
    required double budgetMax,
    required String locationAddress,
    double? lat,
    double? lng,
    DateTime? scheduledAt,
  }) async {
    _isCreating = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final task = await _taskService.createTask(
        title: title,
        description: description,
        category: category,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        locationAddress: locationAddress,
        lat: lat,
        lng: lng,
        scheduledAt: scheduledAt,
      );
      _nearbyTasks = [task, ..._nearbyTasks];
      _myPostedTasks = [task, ..._myPostedTasks];
      notifyListeners();
      return task;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Gagal membuat tugas';
      notifyListeners();
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  // ─── Update local state ───────────────────────────────────────────────────────

  void updateTaskInList(Task updatedTask) {
    _nearbyTasks = _nearbyTasks
        .map((t) => t.id == updatedTask.id ? updatedTask : t)
        .toList();
    _myPostedTasks = _myPostedTasks
        .map((t) => t.id == updatedTask.id ? updatedTask : t)
        .toList();
    _myAppliedTasks = _myAppliedTasks
        .map((t) => t.id == updatedTask.id ? updatedTask : t)
        .toList();
    notifyListeners();
  }
}
