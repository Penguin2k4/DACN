class PredictionModel {
  final String label;
  final double confidence;

  PredictionModel({required this.label, required this.confidence});
  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      label: json['label'] ?? "Unknown",
      confidence: (json['confidence'] is int)
          ? (json['confidence'] as int).toDouble()
          : (json['confidence'] as double),
    );
  }
}