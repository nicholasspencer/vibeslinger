enum WorkspaceFileType { plan, research }

class WorkspaceFile {
  final WorkspaceFileType type;
  final int sessionNumber;
  final int duplicateIndex;
  bool isLoaded;

  WorkspaceFile({
    required this.type,
    required this.sessionNumber,
    this.duplicateIndex = 0,
    this.isLoaded = false,
  });

  String get name {
    final prefix = type == WorkspaceFileType.plan ? 'plan' : 'research';
    final suffix = duplicateIndex > 0 ? '_${duplicateIndex + 1}' : '';
    return '${prefix}_s$sessionNumber$suffix.md';
  }

  double get saveCost => type == WorkspaceFileType.plan ? 0.04 : 0.03;
  double get loadCost => type == WorkspaceFileType.plan ? 0.06 : 0.04;

  double discountedLoadCost({required bool hasFileReader}) {
    return hasFileReader ? loadCost * 0.5 : loadCost;
  }

  double get spreadReduction => type == WorkspaceFileType.plan ? 0.10 : 0.0;
  double get scoutBonus => type == WorkspaceFileType.research ? 0.05 : 0.0;
  double get aimCostReduction => type == WorkspaceFileType.research ? 0.05 : 0.0;
}

class WorkspaceState {
  final List<WorkspaceFile> _files = [];
  int _sessionNumber = 1;

  List<WorkspaceFile> get files => List.unmodifiable(_files);
  int get sessionNumber => _sessionNumber;

  List<WorkspaceFile> get loadedFiles =>
      _files.where((f) => f.isLoaded).toList();

  void saveFile(WorkspaceFileType type) {
    final existing = _files
        .where((f) => f.type == type && f.sessionNumber == _sessionNumber)
        .length;
    _files.add(WorkspaceFile(
      type: type,
      sessionNumber: _sessionNumber,
      duplicateIndex: existing,
    ));
  }

  void loadFile(int index) {
    if (index >= 0 && index < _files.length) {
      _files[index].isLoaded = true;
    }
  }

  void unloadFile(int index) {
    if (index >= 0 && index < _files.length) {
      _files[index].isLoaded = false;
    }
  }

  void newSession() {
    _sessionNumber++;
    for (final file in _files) {
      file.isLoaded = false;
    }
  }

  double get passiveSpreadReduction =>
      loadedFiles.fold(0.0, (sum, f) => sum + f.spreadReduction);

  double get passiveScoutBonus =>
      loadedFiles.fold(0.0, (sum, f) => sum + f.scoutBonus);

  double get passiveAimCostReduction =>
      loadedFiles.fold(0.0, (sum, f) => sum + f.aimCostReduction);
}
