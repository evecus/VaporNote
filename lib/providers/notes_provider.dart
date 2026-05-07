import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../utils/database_helper.dart';

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  String _currentCategory = '全部';
  String _searchQuery = '';
  bool _isLoading = false;
  List<String> _categories = ['全部'];
  Set<String> _selectedIds = {};
  bool _isSelectionMode = false;

  List<Note> get notes => _filteredNotes;
  List<Note> get allNotes => _notes;
  String get currentCategory => _currentCategory;
  bool get isLoading => _isLoading;
  List<String> get categories => _categories;
  Set<String> get selectedIds => _selectedIds;
  bool get isSelectionMode => _isSelectionMode;

  Future<void> loadNotes() async {
    _isLoading = true;
    notifyListeners();

    _notes = await DatabaseHelper.instance.getAllNotes();
    await _refreshCategories();
    _applyFilters();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _refreshCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    _categories = ['全部', ...cats.where((c) => c != '全部')];
  }

  void _applyFilters() {
    List<Note> filtered = _notes;

    if (_currentCategory != '全部') {
      filtered = filtered.where((n) => n.category == _currentCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((n) =>
          n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q) ||
          n.checkItems.any((i) => i.text.toLowerCase().contains(q))).toList();
    }

    _filteredNotes = filtered;
  }

  void setCategory(String category) {
    _currentCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  Future<Note> createNote({String category = '全部'}) async {
    final note = Note(
      id: const Uuid().v4(),
      category: category == '全部' ? '未分类' : category,
    );
    await DatabaseHelper.instance.insertNote(note);
    _notes.insert(0, note);
    await _refreshCategories();
    _applyFilters();
    notifyListeners();
    return note;
  }

  Future<void> saveNote(Note note) async {
    final idx = _notes.indexWhere((n) => n.id == note.id);
    if (idx >= 0) {
      _notes[idx] = note;
      await DatabaseHelper.instance.updateNote(note);
    } else {
      _notes.insert(0, note);
      await DatabaseHelper.instance.insertNote(note);
    }
    await _refreshCategories();
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await DatabaseHelper.instance.deleteNote(id);
    await _refreshCategories();
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    for (final id in _selectedIds) {
      await DatabaseHelper.instance.deleteNote(id);
    }
    _notes.removeWhere((n) => _selectedIds.contains(n.id));
    _selectedIds.clear();
    _isSelectionMode = false;
    await _refreshCategories();
    _applyFilters();
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final idx = _notes.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      final note = _notes[idx].copyWith(isPinned: !_notes[idx].isPinned);
      _notes[idx] = note;
      await DatabaseHelper.instance.updateNote(note);
      _notes.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      _applyFilters();
      notifyListeners();
    }
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    } else {
      _selectedIds.add(id);
      _isSelectionMode = true;
    }
    notifyListeners();
  }

  void startSelection(String id) {
    _isSelectionMode = true;
    _selectedIds.add(id);
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }
}
