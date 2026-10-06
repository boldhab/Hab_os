import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/vault_note_model.dart';

class VaultState {
  final List<VaultNote> notes;
  final List<String> allTags;
  final String? selectedTag;
  final String searchQuery;
  final bool onlyMistakes;
  final bool isLoading;
  final String? errorMessage;

  const VaultState({
    this.notes = const [],
    this.allTags = const [],
    this.selectedTag,
    this.searchQuery = '',
    this.onlyMistakes = false,
    this.isLoading = false,
    this.errorMessage,
  });

  VaultState copyWith({
    List<VaultNote>? notes,
    List<String>? allTags,
    String? selectedTag,
    bool clearSelectedTag = false,
    String? searchQuery,
    bool? onlyMistakes,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VaultState(
      notes: notes ?? this.notes,
      allTags: allTags ?? this.allTags,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      searchQuery: searchQuery ?? this.searchQuery,
      onlyMistakes: onlyMistakes ?? this.onlyMistakes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class VaultNotifier extends StateNotifier<VaultState> {
  final Ref _ref;

  VaultNotifier(this._ref) : super(const VaultState()) {
    refresh();
  }

  Future<void> refresh() async {
    await Future.wait([
      fetchNotes(),
      fetchTags(),
    ]);
  }

  Future<void> fetchTags() async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.vaultTags);
      final data = response.data['data'] ?? response.data;
      if (data is List) {
        final tags = data.map((t) => t.toString()).toList();
        state = state.copyWith(allTags: tags);
      }
    } catch (_) {
      // Keep existing tags on error
    }
  }

  Future<void> fetchNotes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = _ref.read(dioProvider);
      final Map<String, dynamic> query = {};

      if (state.searchQuery.trim().isNotEmpty) {
        query['search'] = state.searchQuery.trim();
      }
      if (state.selectedTag != null && state.selectedTag!.isNotEmpty) {
        query['tag'] = state.selectedTag;
      }
      if (state.onlyMistakes) {
        query['isMistakeSolution'] = true;
      }

      final response = await dio.get(
        ApiEndpoints.vaultNotes,
        queryParameters: query,
      );

      final payload = response.data['data'] ?? response.data;
      final notesListRaw = payload['notes'] ?? payload;

      final List<VaultNote> notes = [];
      if (notesListRaw is List) {
        for (final item in notesListRaw) {
          if (item is Map) {
            notes.add(VaultNote.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      state = state.copyWith(
        notes: notes,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load vault notes: $e',
      );
    }
  }

  void selectTag(String? tag) {
    if (state.selectedTag == tag) {
      state = state.copyWith(clearSelectedTag: true);
    } else {
      state = state.copyWith(selectedTag: tag);
    }
    fetchNotes();
  }

  void toggleOnlyMistakes() {
    state = state.copyWith(onlyMistakes: !state.onlyMistakes);
    fetchNotes();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    fetchNotes();
  }

  Future<VaultNote?> getNoteById(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.get(ApiEndpoints.vaultNoteById(id));
      final data = response.data['data'] ?? response.data;
      if (data is Map) {
        return VaultNote.fromJson(Map<String, dynamic>.from(data));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<VaultNote?> createNote({
    required String title,
    required String content,
    List<String> tags = const [],
    List<CodeSnippet> codeSnippets = const [],
    bool isMistakeSolution = false,
    String? categoryId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = _ref.read(dioProvider);
      final response = await dio.post(
        ApiEndpoints.vaultNotes,
        data: {
          'title': title,
          'content': content,
          'tags': tags,
          'codeSnippets': codeSnippets.map((s) => s.toJson()).toList(),
          'isMistakeSolution': isMistakeSolution,
          if (categoryId != null) 'categoryId': categoryId,
        },
      );

      final data = response.data['data'] ?? response.data;
      final newNote = VaultNote.fromJson(Map<String, dynamic>.from(data));

      state = state.copyWith(
        notes: [newNote, ...state.notes],
        isLoading: false,
      );

      await fetchTags();
      return newNote;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create note: $e',
      );
      return null;
    }
  }

  Future<bool> updateNote(String id, {
    String? title,
    String? content,
    List<String>? tags,
    List<CodeSnippet>? codeSnippets,
    bool? isMistakeSolution,
    String? categoryId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dio = _ref.read(dioProvider);
      final Map<String, dynamic> updateData = {};
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (tags != null) updateData['tags'] = tags;
      if (codeSnippets != null) {
        updateData['codeSnippets'] = codeSnippets.map((s) => s.toJson()).toList();
      }
      if (isMistakeSolution != null) updateData['isMistakeSolution'] = isMistakeSolution;
      if (categoryId != null) updateData['categoryId'] = categoryId;

      final response = await dio.put(
        ApiEndpoints.vaultNoteById(id),
        data: updateData,
      );

      final data = response.data['data'] ?? response.data;
      final updated = VaultNote.fromJson(Map<String, dynamic>.from(data));

      final updatedList = state.notes.map((n) => n.id == id ? updated : n).toList();
      state = state.copyWith(notes: updatedList, isLoading: false);

      await fetchTags();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update note: $e',
      );
      return false;
    }
  }

  Future<bool> deleteNote(String id) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete(ApiEndpoints.vaultNoteById(id));

      final remaining = state.notes.where((n) => n.id != id).toList();
      state = state.copyWith(notes: remaining);
      await fetchTags();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete note: $e');
      return false;
    }
  }

  Future<bool> linkNotes(String sourceId, String targetId) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.post(ApiEndpoints.vaultLinks, data: {
        'sourceNoteId': sourceId,
        'targetNoteId': targetId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> unlinkNotes(String sourceId, String targetId) async {
    try {
      final dio = _ref.read(dioProvider);
      await dio.delete(ApiEndpoints.vaultLinks, data: {
        'sourceNoteId': sourceId,
        'targetNoteId': targetId,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}

final vaultProvider =
    StateNotifierProvider.autoDispose<VaultNotifier, VaultState>((ref) {
  return VaultNotifier(ref);
});

final singleVaultNoteProvider =
    FutureProvider.autoDispose.family<VaultNote?, String>((ref, noteId) async {
  final notifier = ref.read(vaultProvider.notifier);
  return notifier.getNoteById(noteId);
});
