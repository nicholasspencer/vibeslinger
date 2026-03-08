enum ToolType {
  webSearch,
  codeAnalysis,
  fileReader,
}

class Tool {
  final ToolType type;
  final String name;
  final double systemCost;
  final String passiveBenefit;
  final double scoutBonus;
  final double accuracyBonus;
  final double spreadBonus;

  const Tool({
    required this.type,
    required this.name,
    required this.systemCost,
    required this.passiveBenefit,
    this.scoutBonus = 0.0,
    this.accuracyBonus = 0.0,
    this.spreadBonus = 0.0,
  });

  static const List<Tool> all = [
    Tool(
      type: ToolType.webSearch,
      name: 'Web Search',
      systemCost: 0.08,
      passiveBenefit: '+10% scout effectiveness',
      scoutBonus: 0.10,
    ),
    Tool(
      type: ToolType.codeAnalysis,
      name: 'Code Analysis',
      systemCost: 0.10,
      passiveBenefit: '+10% base accuracy',
      accuracyBonus: 0.10,
    ),
    Tool(
      type: ToolType.fileReader,
      name: 'File Reader',
      systemCost: 0.06,
      passiveBenefit: '-5% spread',
      spreadBonus: 0.05,
    ),
  ];
}
