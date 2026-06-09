/// Web 端数据库存根 —— sqflite 不支持 Web，返回 null 使用占位数据
/// 同名类和接口，通过条件导入与 mobile 版本互换

class InfiltrationRecord {
  final double? mean;
  final double? median;
  final double? ci95Low;
  final double? ci95High;
  final double? ci75Low;
  final double? ci75High;

  const InfiltrationRecord({
    this.mean,
    this.median,
    this.ci95Low,
    this.ci95High,
    this.ci75Low,
    this.ci75High,
  });

  double? get displayValue => mean ?? median;
  bool get hasData => displayValue != null;
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  factory DatabaseHelper() => instance;
  DatabaseHelper._();

  Future<void> init() async {}
  void close() {}

  Future<InfiltrationRecord?> query(int regionId, int year, int month) async {
    return null; // Web 端无数据库
  }
}
