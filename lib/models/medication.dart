import 'package:equatable/equatable.dart';

class Medication extends Equatable {
  final int? id;
  final String tradeName;
  final String arabicName;
  final double oldPrice;
  final double price;
  final String active;
  final String mainCategory;
  final String mainCategoryAr;
  final String category;
  final String categoryAr;
  final String company;
  final String dosageForm;
  final String dosageFormAr;
  final String unit;
  final String usage;
  final String usageAr;
  final String description;
  final String lastPriceUpdate;
  final bool isFavorite;

  const Medication({
    this.id,
    required this.tradeName,
    required this.arabicName,
    required this.oldPrice,
    required this.price,
    required this.active,
    required this.mainCategory,
    required this.mainCategoryAr,
    required this.category,
    required this.categoryAr,
    required this.company,
    required this.dosageForm,
    required this.dosageFormAr,
    required this.unit,
    required this.usage,
    required this.usageAr,
    required this.description,
    required this.lastPriceUpdate,
    this.isFavorite = false,
  });

  // Calculate price difference percentage
  double get priceDifferencePercentage {
    if (oldPrice == 0) return 0;
    return ((price - oldPrice) / oldPrice) * 100;
  }

  // Check if price has increased
  bool get hasPriceIncreased => price > oldPrice;

  // Factory constructor to create a Medication from a JSON map
  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      id: json['id'] as int?,
      tradeName: json['trade_name'] as String? ?? '',
      arabicName: json['arabic_name'] as String? ?? '',
      oldPrice:
          json['old_price'] is double
              ? json['old_price']
              : double.tryParse(json['old_price'].toString()) ?? 0.0,
      price:
          json['price'] is double
              ? json['price']
              : double.tryParse(json['price'].toString()) ?? 0.0,
      active: json['active'] as String? ?? '',
      mainCategory: json['main_category'] as String? ?? '',
      mainCategoryAr: json['main_category_ar'] as String? ?? '',
      category: json['category'] as String? ?? '',
      categoryAr: json['category_ar'] as String? ?? '',
      company: json['company'] as String? ?? '',
      dosageForm: json['dosage_form'] as String? ?? '',
      dosageFormAr: json['dosage_form_ar'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      usage: json['usage'] as String? ?? '',
      usageAr: json['usage_ar'] as String? ?? '',
      description: json['description'] as String? ?? '',
      lastPriceUpdate: json['last_price_update'] as String? ?? '',
      isFavorite: json['is_favorite'] == 1,
    );
  }

  // Factory constructor to create a Medication from a list
  factory Medication.fromList(List<dynamic> list) {
    return Medication(
      tradeName: list[1] as String? ?? '',
      arabicName: list[2] as String? ?? '',
      oldPrice:
          list[3] is double
              ? list[3]
              : double.tryParse(list[3].toString()) ?? 0.0,
      price:
          list[4] is double
              ? list[4]
              : double.tryParse(list[4].toString()) ?? 0.0,
      active: list[5] as String? ?? '',
      mainCategory: list[6] as String? ?? '',
      mainCategoryAr: list[7] as String? ?? '',
      category: list[8] as String? ?? '',
      categoryAr: list[9] as String? ?? '',
      company: list[10] as String? ?? '',
      dosageForm: list[11] as String? ?? '',
      dosageFormAr: list[12] as String? ?? '',
      unit: list[13] as String? ?? '',
      usage: list[14] as String? ?? '',
      usageAr: list[15] as String? ?? '',
      description: list[16] as String? ?? '',
      lastPriceUpdate: list[17] as String? ?? '',
      isFavorite: false,
    );
  }

  // Convert a Medication to a map
  Map<String, dynamic> toMap() {
    return {
      'trade_name': tradeName,
      'arabic_name': arabicName,
      'old_price': oldPrice,
      'price': price,
      'active': active,
      'main_category': mainCategory,
      'main_category_ar': mainCategoryAr,
      'category': category,
      'category_ar': categoryAr,
      'company': company,
      'dosage_form': dosageForm,
      'dosage_form_ar': dosageFormAr,
      'unit': unit,
      'usage': usage,
      'usage_ar': usageAr,
      'description': description,
      'last_price_update': lastPriceUpdate,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  // Create a copy of Medication with some fields changed
  Medication copyWith({
    int? id,
    String? tradeName,
    String? arabicName,
    double? oldPrice,
    double? price,
    String? active,
    String? mainCategory,
    String? mainCategoryAr,
    String? category,
    String? categoryAr,
    String? company,
    String? dosageForm,
    String? dosageFormAr,
    String? unit,
    String? usage,
    String? usageAr,
    String? description,
    String? lastPriceUpdate,
    bool? isFavorite,
  }) {
    return Medication(
      id: id ?? this.id,
      tradeName: tradeName ?? this.tradeName,
      arabicName: arabicName ?? this.arabicName,
      oldPrice: oldPrice ?? this.oldPrice,
      price: price ?? this.price,
      active: active ?? this.active,
      mainCategory: mainCategory ?? this.mainCategory,
      mainCategoryAr: mainCategoryAr ?? this.mainCategoryAr,
      category: category ?? this.category,
      categoryAr: categoryAr ?? this.categoryAr,
      company: company ?? this.company,
      dosageForm: dosageForm ?? this.dosageForm,
      dosageFormAr: dosageFormAr ?? this.dosageFormAr,
      unit: unit ?? this.unit,
      usage: usage ?? this.usage,
      usageAr: usageAr ?? this.usageAr,
      description: description ?? this.description,
      lastPriceUpdate: lastPriceUpdate ?? this.lastPriceUpdate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [
    id,
    tradeName,
    arabicName,
    oldPrice,
    price,
    active,
    mainCategory,
    mainCategoryAr,
    category,
    categoryAr,
    company,
    dosageForm,
    dosageFormAr,
    unit,
    usage,
    usageAr,
    description,
    lastPriceUpdate,
    isFavorite,
  ];
}
