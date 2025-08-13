class ComfortEfficiencyModel {
  final double acAvoidancePercentage;
  final double estimatedSavings;
  final String month;
  final bool isPremiumUser;

  ComfortEfficiencyModel({
    required this.acAvoidancePercentage,
    required this.estimatedSavings,
    required this.month,
    required this.isPremiumUser,
  });

  // Mock data factory for demonstration
  factory ComfortEfficiencyModel.mockData({bool isPremium = false}) {
    return ComfortEfficiencyModel(
      acAvoidancePercentage: 64.0,
      estimatedSavings: 18.20,
      month: 'July',
      isPremiumUser: isPremium,
    );
  }
}
