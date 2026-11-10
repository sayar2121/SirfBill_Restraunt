import 'package:flutter/material.dart';
import '../../../models/restaurant_pos_models.dart';
import '../../../utils/app_image_cache_manager.dart';

class WaiterMenuCard extends StatelessWidget {
  final PosMenuItem item;
  final int cartQuantity;
  final VoidCallback onAdd;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const WaiterMenuCard({
    super.key,
    required this.item,
    required this.cartQuantity,
    required this.onAdd,
    this.onIncrement,
    this.onDecrement,
  });

  static const Map<String, String> foodImages = {
    'Masala Tea': 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=300&auto=format&fit=crop&q=60',
    'Cold Coffee': 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=300&auto=format&fit=crop&q=60',
    'Veg Sandwich': 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=300&auto=format&fit=crop&q=60',
    'Paneer Tikka': 'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=300&auto=format&fit=crop&q=60',
    'French Fries': 'https://images.unsplash.com/photo-1576107232684-1279f3908594?w=300&auto=format&fit=crop&q=60',
    'Margherita Pizza': 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?w=300&auto=format&fit=crop&q=60',
    'Farmhouse Pizza': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=300&auto=format&fit=crop&q=60',
    'Veg Burger': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=300&auto=format&fit=crop&q=60',
    'Veg Biryani': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=300&auto=format&fit=crop&q=60',
    'Dal Makhani': 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=300&auto=format&fit=crop&q=60',
    'Butter Naan': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=300&auto=format&fit=crop&q=60',
    'Garlic Naan': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=300&auto=format&fit=crop&q=60',
    'Paneer Butter Masala': 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?w=300&auto=format&fit=crop&q=60',
    'Chole Bhature': 'https://images.unsplash.com/photo-1626777552726-4a6b54c97e46?w=300&auto=format&fit=crop&q=60',
    'Fried Rice': 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=300&auto=format&fit=crop&q=60',
    'Manchurian': 'https://images.unsplash.com/photo-1569058242253-92a9c755a0ec?w=300&auto=format&fit=crop&q=60',
    'Hakka Noodles': 'https://images.unsplash.com/photo-1612927601601-6638404737ce?w=300&auto=format&fit=crop&q=60',
    'Veg Thali': 'https://images.unsplash.com/photo-1610057099443-fde8c4d50f91?w=300&auto=format&fit=crop&q=60',
    'Gulab Jamun': 'https://images.unsplash.com/photo-1605197161470-ff6552973719?w=300&auto=format&fit=crop&q=60',
    'Ice Cream': 'https://images.unsplash.com/photo-1497034825429-c343d7c6a68f?w=300&auto=format&fit=crop&q=60',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = cartQuantity > 0
        ? const Color(0xFFF59E0B)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final imgUrl = item.imageUrl ?? foodImages[item.name];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onAdd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: cartQuantity > 0 ? 2.0 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: cartQuantity > 0
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.2)
                    : (isDark ? Colors.black38 : const Color(0xFF0F172A).withValues(alpha: 0.04)),
                blurRadius: cartQuantity > 0 ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Food Image Header with 16:9 ratio
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imgUrl != null && imgUrl.isNotEmpty
                        ? CachedAppImage(
                            url: imgUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 360,
                            cacheHeight: 220,
                            errorBuilder: (_, isDk) => _buildFallbackImage(isDk),
                          )
                        : _buildFallbackImage(isDark),

                    // Top Left: Veg / Non-Veg Indicator
                    Positioned(
                      top: 7,
                      left: 7,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: item.isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.isVeg ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Top Right: Badge (e.g. Bestseller, Chef Special)
                    if (item.badge != null && item.badge!.isNotEmpty)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.badge == 'Bestseller'
                                  ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Text(
                            item.badge!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                    // In-Cart Badge Indicator
                    if (cartQuantity > 0)
                      Positioned(
                        bottom: 6,
                        left: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, color: Colors.white, size: 11),
                              const SizedBox(width: 3),
                              Text(
                                '$cartQuantity in cart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 2. Info & Action Section (Compact, balanced, overflow-safe)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(9, 5, 9, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dish Name (Controlled height & scale-safe)
                      Expanded(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Price & Stepper Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Price & Code (Flexible & scale-safe)
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF059669),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (item.shortCode != null && item.shortCode!.isNotEmpty) ...[
                                    const SizedBox(width: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.shortCode!,
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // In-Card Stepper or Add button
                          if (cartQuantity > 0)
                            Container(
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: onDecrement,
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                      child: Container(
                                        width: 26,
                                        height: 30,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.remove_rounded, color: Colors.white, size: 15),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: Text(
                                      '$cartQuantity',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: onIncrement ?? onAdd,
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                      child: Container(
                                        width: 26,
                                        height: 30,
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 15),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: onAdd,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 14, color: Color(0xFFD97706)),
                                      SizedBox(width: 2),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackImage(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 32,
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}
