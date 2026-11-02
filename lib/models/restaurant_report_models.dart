class SalesReportSummary {
  final double grossSales;
  final double netSales;
  final double totalDiscount;
  final double totalGst;
  final int totalOrders;
  final double averageOrderValue;
  final int totalItemsSold;
  final int uniqueCustomers;
  final double upiSales;
  final double cashSales;
  final double cardSales;
  final double dineInSales;
  final double takeawaySales;
  final double deliverySales;

  const SalesReportSummary({
    required this.grossSales,
    required this.netSales,
    required this.totalDiscount,
    required this.totalGst,
    required this.totalOrders,
    required this.averageOrderValue,
    this.totalItemsSold = 0,
    this.uniqueCustomers = 0,
    required this.upiSales,
    required this.cashSales,
    required this.cardSales,
    required this.dineInSales,
    required this.takeawaySales,
    required this.deliverySales,
  });
}

class TopSellingDish {
  final String name;
  final String category;
  final int quantitySold;
  final double revenue;

  const TopSellingDish({
    required this.name,
    required this.category,
    required this.quantitySold,
    required this.revenue,
  });
}

class AuditLogEntry {
  final String id;
  final String action; // e.g. "Bill Settled", "Discount Applied", "KOT Printed"
  final String actorName;
  final String details;
  final DateTime timestamp;
  final String severity; // "info", "warning", "critical"

  const AuditLogEntry({
    required this.id,
    required this.action,
    required this.actorName,
    required this.details,
    required this.timestamp,
    this.severity = 'info',
  });
}
