import 'package:flutter/material.dart';
import '../../../../services/shop_service.dart';

class ShopTable extends StatefulWidget {
  final List<Shop> shops;
  final bool isLoading;
  final void Function(Shop)? onEdit;

  const ShopTable({super.key, required this.shops, this.isLoading = false, this.onEdit});

  @override
  State<ShopTable> createState() => _ShopTableState();
}

class _ShopTableState extends State<ShopTable> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  Widget _buildHeader(String title, int flex) {
    return Expanded(
      flex: flex,
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569))),
    );
  }

  Widget _buildDesktopTable(List<Shop> paginatedShops) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent, 
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569)))),
              _buildHeader('Shop Name', 2),
              _buildHeader('Shop Code', 1),
              _buildHeader('Location', 1),
              _buildHeader('City', 1),
              _buildHeader('Contact', 1),
              _buildHeader('Status', 1),
              SizedBox(width: 100, child: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569)))),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: paginatedShops.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
          itemBuilder: (context, index) {
            final shop = paginatedShops[index];
            final isActive = shop.status.toLowerCase() == 'active';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 32, 
                    child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                shop.name, 
                                maxLines: 1, 
                                overflow: TextOverflow.ellipsis, 
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 13),
                              ),
                            ),
                            if (shop.isPrimary) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E), 
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ]
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('SirfBill', style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : const Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Text(shop.code, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569), fontSize: 13))),
                  Expanded(
                    flex: 1, 
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : const Color(0xFF94A3B8)), 
                        const SizedBox(width: 4), 
                        Expanded(
                          child: Text(shop.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Text(shop.city, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569), fontSize: 13))),
                  Expanded(
                    flex: 1, 
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : const Color(0xFF94A3B8)), 
                        const SizedBox(width: 4), 
                        Expanded(
                          child: Text(shop.contact, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7)) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2)), 
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                            const SizedBox(width: 4),
                            Text(
                              shop.status, 
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          icon: Icon(Icons.edit, size: 14, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
                          label: Text('Edit', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12), 
                            minimumSize: const Size(0, 32),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () {
                            if (widget.onEdit != null) widget.onEdit!(shop);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMobileCards(List<Shop> paginatedShops) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paginatedShops.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final shop = paginatedShops[index];
        final isActive = shop.status.toLowerCase() == 'active';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            shop.name, 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis, 
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B), fontSize: 16),
                          ),
                        ),
                        if (shop.isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E), 
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ]
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7)) : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2)), 
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                        const SizedBox(width: 4),
                        Text(
                          shop.status, 
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMobileDetailRow(Icons.tag, 'Code', shop.code),
              const SizedBox(height: 8),
              _buildMobileDetailRow(Icons.location_on, 'Location', '${shop.location}, ${shop.city}'),
              const SizedBox(height: 8),
              _buildMobileDetailRow(Icons.phone, 'Contact', shop.contact),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.edit, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B)),
                      label: Text('Edit', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B))),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12), 
                        side: BorderSide(color: Theme.of(context).dividerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (widget.onEdit != null) widget.onEdit!(shop);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : const Color(0xFF475569), fontSize: 13),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
    }
    if (widget.shops.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(48), child: Text('No shops found')));
    }

    final totalPages = (widget.shops.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) {
      _currentPage = totalPages;
    } else if (totalPages == 0) {
      _currentPage = 1;
    }

    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage < widget.shops.length) 
        ? startIndex + _itemsPerPage 
        : widget.shops.length;
    
    final paginatedShops = widget.shops.sublist(startIndex, endIndex);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;
        
        return Column(
          children: [
            isDesktop ? _buildDesktopTable(paginatedShops) : _buildMobileCards(paginatedShops),
            
            // Footer (Dynamic Pagination)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${startIndex + 1} to $endIndex of ${widget.shops.length} shops', 
                    style: TextStyle(fontSize: 12, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : const Color(0xFF94A3B8)),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor), 
                            borderRadius: BorderRadius.circular(6),
                            color: _currentPage > 1 ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          ),
                          child: Icon(Icons.chevron_left, size: 16, color: _currentPage > 1 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(color: const Color(0xFF22C55E), borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('$_currentPage', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor), 
                            borderRadius: BorderRadius.circular(6),
                            color: _currentPage < totalPages ? Colors.transparent : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          ),
                          child: Icon(Icons.chevron_right, size: 16, color: _currentPage < totalPages ? const Color(0xFF1E293B) : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
