import 'package:flutter_test/flutter_test.dart';
import 'package:inference_gunslinger/models/workspace.dart';

void main() {
  group('WorkspaceFile', () {
    test('has correct properties', () {
      final file = WorkspaceFile(
        type: WorkspaceFileType.plan,
        sessionNumber: 1,
      );
      expect(file.type, WorkspaceFileType.plan);
      expect(file.sessionNumber, 1);
      expect(file.name, 'plan_s1.md');
      expect(file.isLoaded, false);
    });

    test('plan has correct costs', () {
      final file = WorkspaceFile(type: WorkspaceFileType.plan, sessionNumber: 1);
      expect(file.saveCost, 0.04);
      expect(file.loadCost, 0.06);
    });

    test('research has correct costs', () {
      final file = WorkspaceFile(type: WorkspaceFileType.research, sessionNumber: 2);
      expect(file.saveCost, 0.03);
      expect(file.loadCost, 0.04);
      expect(file.name, 'research_s2.md');
    });
  });

  group('WorkspaceState', () {
    late WorkspaceState workspace;

    setUp(() {
      workspace = WorkspaceState();
    });

    test('starts empty at session 1', () {
      expect(workspace.files, isEmpty);
      expect(workspace.sessionNumber, 1);
    });

    test('saveFile adds a file', () {
      workspace.saveFile(WorkspaceFileType.plan);
      expect(workspace.files.length, 1);
      expect(workspace.files[0].name, 'plan_s1.md');
    });

    test('saveFile increments file count per type per session', () {
      workspace.saveFile(WorkspaceFileType.plan);
      workspace.saveFile(WorkspaceFileType.plan);
      expect(workspace.files.length, 2);
      expect(workspace.files[1].name, 'plan_s1_2.md');
    });

    test('loadFile sets isLoaded true', () {
      workspace.saveFile(WorkspaceFileType.plan);
      workspace.loadFile(0);
      expect(workspace.files[0].isLoaded, true);
    });

    test('unloadFile sets isLoaded false', () {
      workspace.saveFile(WorkspaceFileType.plan);
      workspace.loadFile(0);
      workspace.unloadFile(0);
      expect(workspace.files[0].isLoaded, false);
    });

    test('newSession increments session number and unloads all', () {
      workspace.saveFile(WorkspaceFileType.plan);
      workspace.loadFile(0);
      workspace.newSession();
      expect(workspace.sessionNumber, 2);
      expect(workspace.files[0].isLoaded, false);
      expect(workspace.files.length, 1); // file persists
    });

    test('loadedFiles returns only loaded files', () {
      workspace.saveFile(WorkspaceFileType.plan);
      workspace.saveFile(WorkspaceFileType.research);
      workspace.loadFile(0);
      expect(workspace.loadedFiles.length, 1);
      expect(workspace.loadedFiles[0].type, WorkspaceFileType.plan);
    });

    test('passive spread reduction from loaded plan', () {
      workspace.saveFile(WorkspaceFileType.plan);
      workspace.loadFile(0);
      expect(workspace.passiveSpreadReduction, 0.10);
    });

    test('passive scout bonus from loaded research', () {
      workspace.saveFile(WorkspaceFileType.research);
      workspace.loadFile(0);
      expect(workspace.passiveScoutBonus, 0.05);
    });

    test('passive aim cost reduction from loaded research', () {
      workspace.saveFile(WorkspaceFileType.research);
      workspace.loadFile(0);
      expect(workspace.passiveAimCostReduction, 0.05);
    });

    test('no passive bonuses when nothing loaded', () {
      workspace.saveFile(WorkspaceFileType.plan);
      // not loaded
      expect(workspace.passiveSpreadReduction, 0.0);
      expect(workspace.passiveScoutBonus, 0.0);
      expect(workspace.passiveAimCostReduction, 0.0);
    });

    test('file reader discount halves load cost', () {
      workspace.saveFile(WorkspaceFileType.plan);
      expect(workspace.files[0].loadCost, 0.06);
      expect(workspace.files[0].discountedLoadCost(hasFileReader: true), 0.03);
    });

    test('no discount without file reader', () {
      workspace.saveFile(WorkspaceFileType.plan);
      expect(workspace.files[0].discountedLoadCost(hasFileReader: false), 0.06);
    });
  });
}
