enum ToolType {
  webSearch,
  codeAnalysis,
  fileReader,
  codeReview,
  skillCreator,
}

class Tool {
  final ToolType type;
  final String name;
  final double systemCost;
  final String passiveBenefit;
  final double scoutBonus;
  final double accuracyBonus;
  final double spreadBonus;

  final double heatPenalty;
  final double shotCostPenalty;
  final int scoutNegations;

  const Tool({
    required this.type,
    required this.name,
    required this.systemCost,
    required this.passiveBenefit,
    this.scoutBonus = 0.0,
    this.accuracyBonus = 0.0,
    this.spreadBonus = 0.0,
    this.heatPenalty = 0.0,
    this.shotCostPenalty = 0.0,
    this.scoutNegations = 0,
  });

  static const List<Tool> all = [
    Tool(
      type: ToolType.webSearch,
      name: 'Web Search',
      systemCost: 0.08,
      passiveBenefit: '+10% scout effectiveness',
      scoutBonus: 0.10,
      shotCostPenalty: 0.005,
    ),
    Tool(
      type: ToolType.codeAnalysis,
      name: 'Code Analysis',
      systemCost: 0.10,
      passiveBenefit: '+10% base accuracy',
      accuracyBonus: 0.10,
      shotCostPenalty: 0.01,
    ),
    Tool(
      type: ToolType.fileReader,
      name: 'File Reader',
      systemCost: 0.06,
      passiveBenefit: '-5% spread',
      spreadBonus: 0.05,
      shotCostPenalty: 0.005,
    ),
    Tool(
      type: ToolType.codeReview,
      name: 'Code Review',
      systemCost: 0.12,
      passiveBenefit: '+5% accuracy, -8% spread',
      accuracyBonus: 0.05,
      spreadBonus: 0.08,
      heatPenalty: 0.5,
      shotCostPenalty: 0.015,
    ),
    Tool(
      type: ToolType.skillCreator,
      name: 'Skill Creator',
      systemCost: 0.15,
      passiveBenefit: '+25% accuracy, removes 1 penalty',
      accuracyBonus: 0.25,
      scoutNegations: 1,
      shotCostPenalty: 0.02,
    ),
  ];
}
