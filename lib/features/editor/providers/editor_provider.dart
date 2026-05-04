import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/berkas_model.dart';
import '../../../shared/models/section_model.dart';
import '../../../data/repositories/berkas_repository.dart';
import '../../berkas/providers/berkas_provider.dart';
import 'package:uuid/uuid.dart';

class EditorState {
  final BerkasModel? berkas;
  final bool isDirty;
  final bool isSaving;

  const EditorState({
    this.berkas,
    this.isDirty = false,
    this.isSaving = false,
  });

  EditorState copyWith({
    BerkasModel? berkas,
    bool? isDirty,
    bool? isSaving,
  }) {
    return EditorState(
      berkas: berkas ?? this.berkas,
      isDirty: isDirty ?? this.isDirty,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

final editorProvider =
    StateNotifierProvider<EditorNotifier, EditorState>((ref) {
  return EditorNotifier(
    ref.read(berkasRepositoryProvider),
    ref,
  );
});

class EditorNotifier extends StateNotifier<EditorState> {
  final BerkasRepository _repository;
  final Ref _ref;
  static const _uuid = Uuid();

  EditorNotifier(this._repository, this._ref) : super(const EditorState());

  void loadBerkas(BerkasModel berkas) {
    state = EditorState(berkas: berkas);
  }

  void updateTitle(String title) {
    if (state.berkas == null) return;
    state = state.copyWith(
      berkas: state.berkas!.copyWith(title: title),
      isDirty: true,
    );
  }

  void updateBackground(BerkasBackground type, String value) {
    if (state.berkas == null) return;
    state = state.copyWith(
      berkas: state.berkas!
          .copyWith(backgroundType: type, backgroundValue: value),
      isDirty: true,
    );
  }

  void addSection(SectionType type) {
    if (state.berkas == null) return;
    final sections = List<SectionModel>.from(state.berkas!.sections);
    final newSection = SectionModel(
      id: _uuid.v4(),
      type: type,
      order: sections.length,
      data: _defaultDataFor(type),
    );
    sections.add(newSection);
    state = state.copyWith(
      berkas: state.berkas!.copyWith(sections: sections),
      isDirty: true,
    );
  }

  void updateSection(SectionModel updated) {
    if (state.berkas == null) return;
    final sections = state.berkas!.sections
        .map((s) => s.id == updated.id ? updated : s)
        .toList();
    state = state.copyWith(
      berkas: state.berkas!.copyWith(sections: sections),
      isDirty: true,
    );
  }

  void removeSection(String sectionId) {
    if (state.berkas == null) return;
    final sections = state.berkas!.sections
        .where((s) => s.id != sectionId)
        .toList();
    // Re-order
    for (var i = 0; i < sections.length; i++) {
      sections[i].order = i;
    }
    state = state.copyWith(
      berkas: state.berkas!.copyWith(sections: sections),
      isDirty: true,
    );
  }

  void reorderSections(int oldIndex, int newIndex) {
    if (state.berkas == null) return;
    final sections = List<SectionModel>.from(state.berkas!.sections);
    if (newIndex > oldIndex) newIndex--;
    final item = sections.removeAt(oldIndex);
    sections.insert(newIndex, item);
    for (var i = 0; i < sections.length; i++) {
      sections[i].order = i;
    }
    state = state.copyWith(
      berkas: state.berkas!.copyWith(sections: sections),
      isDirty: true,
    );
  }

  Future<void> save() async {
    if (state.berkas == null || !state.isDirty) return;
    state = state.copyWith(isSaving: true);
    try {
      final updated = state.berkas!.copyWith(updatedAt: DateTime.now());
      await _repository.save(updated);
      _ref.read(berkasProvider.notifier).refresh();
      state = state.copyWith(berkas: updated, isSaving: false, isDirty: false);
    } catch (_) {
      state = state.copyWith(isSaving: false);
    }
  }

  Map<String, dynamic> _defaultDataFor(SectionType type) => switch (type) {
        SectionType.wawancara => SectionModel.defaultWawancara(),
        SectionType.checklist => SectionModel.defaultChecklist(),
        SectionType.pilihanGanda => SectionModel.defaultPilihanGanda(),
        SectionType.esai => SectionModel.defaultEsai(),
        SectionType.tandaTangan => SectionModel.defaultTandaTangan(),
        SectionType.gambar => SectionModel.defaultGambar(),
        SectionType.tabel => SectionModel.defaultTabel(),
        SectionType.teksBebas => SectionModel.defaultTeksBebas(),
      };
}
