class FormatUtils {
  static String formatQty(Map<String, dynamic> item, {String key = 'qty'}) {
    int qty;
    final rawQty = item[key];
    if (rawQty is String) {
      qty = double.tryParse(rawQty)?.toInt() ?? 1;
    } else if (rawQty is num) {
      qty = rawQty.toInt();
    } else {
      qty = 1;
    }

    if (item['is_loose'] == true) {
      int packSize = 1;
      if (item['pack_size'] is int) {
        packSize = item['pack_size'] as int;
      } else if (item['pack_size'] != null) {
        packSize = int.tryParse(item['pack_size'].toString()) ?? 1;
      }
      
      if (packSize > 1) {
        int packs = qty ~/ packSize;
        int pieces = qty % packSize;
        if (packs > 0 && pieces > 0) {
          return '$packs pk, $pieces pc';
        } else if (packs > 0) {
          return '$packs pk';
        } else {
          return '$pieces pc';
        }
      }
      return '$qty pc';
    }
    return qty.toString();
  }

  static String formatInventoryStock(Map<String, dynamic> item) {
    int stock = item['stock'] ?? 0;
    int looseStock = item['loose_stock'] ?? 0;
    
    if (looseStock > 0) {
      return '$stock Pk, $looseStock Pc';
    }
    return stock.toString();
  }
}
