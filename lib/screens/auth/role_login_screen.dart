import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/windows_auto_updater.dart';

class RoleLoginScreen extends StatefulWidget {
  final String roleName;
  final Color themeColor;
  final String nextRoute;

  const RoleLoginScreen({
    super.key,
    required this.roleName,
    required this.themeColor,
    required this.nextRoute,
  });

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  bool _isLoading = false;
  bool _isCheckingUpdate = false;

  Future<void> _manualCheckUpdate() async {
    setState(() {
      _isCheckingUpdate = true;
    });
    try {
      await WindowsAutoUpdater.checkAndShowUpdateIfAvailable(
        context,
        showFeedbackWhenLatest: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {


      setState(() {
        _isLoading = true;
      });

      // Let backend validate credentials and role permissions
      final rawEmail = _userIdController.text.trim();
      final rawPass = _passwordController.text.trim();

      try {
        final success = await AuthService.adminLogin(
          rawEmail,
          rawPass,
        );

        if (success && mounted) {
          context.go(widget.nextRoute);
        }
      } catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Login Failed', style: TextStyle(color: Colors.red)),
                ],
              ),
              content: Text(e.toString().replaceAll('Exception: ', '')),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: widget.themeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final shaderColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Stack(
      children: [
        // Solid Background
        Positioned.fill(
          child: Container(color: scaffoldBg),
        ),
        // Background Image (Blurred)
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [shaderColor, shaderColor.withValues(alpha: 0.2)],
                stops: const [0.4, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstOut,
            child: Image.asset(
              'assets/back.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
          ),
        ),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  scaffoldBg.withValues(alpha: 0.95),
                  scaffoldBg.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        // Foreground UI
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              // Custom Top Bar
              Container(
                color: widget.themeColor,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 4,
                  bottom: 8,
                  left: 24,
                  right: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      '${widget.roleName} Login',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!kIsWeb)
                          TextButton.icon(
                            onPressed: _isCheckingUpdate ? null : _manualCheckUpdate,
                            icon: _isCheckingUpdate
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.system_update_alt_rounded, color: Colors.white, size: 16),
                            label: Text(
                              _isCheckingUpdate ? 'Checking...' : 'Check Updates',
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        if (isWeb) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'Sirfbill Restaurant • Naiyo24',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(child: isWeb ? _buildWebLayout() : _buildMobileLayout()),

              // Footer
              if (isWeb)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '© 2026 Sirfbill Restaurant. All rights reserved.',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      Row(
                        children: [
                          const Text(
                            'Smart Restaurant POS & Operations',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.restaurant_rounded, size: 14, color: widget.themeColor),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ), // Closes Column
        ), // Closes Scaffold
      ],
    ); // Closes Stack
  }

  Widget _buildWebLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
              // Left Content
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                      height: 80,
                      cacheHeight: 250,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to',
                      style: TextStyle(fontSize: 24, color: subtitleColor),
                    ),
                    Text(
                      '${widget.roleName} Module',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: widget.themeColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.roleName == 'Restaurant POS' || widget.roleName == 'Billing Counter'
                          ? 'Lightning-fast restaurant billing, dine-in tables,\ntakeaway orders and split payment processing.'
                          : widget.roleName == 'Kitchen Display'
                          ? 'Manage digital KOTs, live kitchen tickets\nand real-time preparation status effortlessly.'
                          : widget.roleName == 'Inventory & Purchase'
                          ? 'Track ingredients, recipe consumption, suppliers\nand live stock movements accurately.'
                          : 'Guest profiles, loyalty rewards, repeat visits\nand real-time sales performance analytics.',
                      style: TextStyle(
                        fontSize: 16,
                        color: subtitleColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (widget.roleName == 'Restaurant POS' || widget.roleName == 'Billing Counter') ...[
                      _buildFeatureItem(
                        Icons.table_restaurant_rounded,
                        'Table & Dine-in Management',
                        'Assign tables and manage guest orders',
                      ),
                      _buildFeatureItem(
                        Icons.receipt_long_rounded,
                        'Fast POS & KOT Printing',
                        'One-click order punch and thermal receipts',
                      ),
                      _buildFeatureItem(
                        Icons.payments_rounded,
                        'Flexible Payments',
                        'Cash, UPI, Cards and Split bill settlement',
                      ),
                    ] else if (widget.roleName == 'Kitchen Display') ...[
                      _buildFeatureItem(
                        Icons.soup_kitchen_rounded,
                        'Live Kitchen Order Tickets',
                        'Color-coded tickets with preparation timer',
                      ),
                      _buildFeatureItem(
                        Icons.checklist_rounded,
                        'Course & Item Progress',
                        'Mark items preparing, ready or served',
                      ),
                      _buildFeatureItem(
                        Icons.notifications_active_rounded,
                        'Instant Order Sync',
                        'Real-time updates between waiter and kitchen',
                      ),
                    ] else if (widget.roleName == 'Inventory & Purchase') ...[
                      _buildFeatureItem(
                        Icons.inventory_2_rounded,
                        'Ingredient & Recipe BOM',
                        'Automatic stock deduction per dish prepared',
                      ),
                      _buildFeatureItem(
                        Icons.local_shipping_rounded,
                        'Suppliers & Purchase Bills',
                        'Track raw materials and vendor balances',
                      ),
                      _buildFeatureItem(
                        Icons.warning_amber_rounded,
                        'Low Stock & Wastage',
                        'Real-time shortage alerts and wastage logs',
                      ),
                    ] else ...[
                      _buildFeatureItem(
                        Icons.people_alt_rounded,
                        'Customer & Guest Profiles',
                        'Order history, favorites and dining notes',
                      ),
                      _buildFeatureItem(
                        Icons.loyalty_rounded,
                        'Loyalty & Rewards',
                        'Point ledgers, reward points and coupons',
                      ),
                      _buildFeatureItem(
                        Icons.insights_rounded,
                        'Sales & Shift Analytics',
                        'Daily sales, best-selling dishes and reports',
                      ),
                    ],
                  ],
                ),
              ),

              // Right Login Card
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _buildLoginCard(),
                  ),
                ),
              ),
            ],
          ), // Closes Row
        ), // Closes Padding
      ), // Closes SingleChildScrollView
    ), // Closes ConstrainedBox
  ); // Closes Center
}

  Widget _buildMobileLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Image.asset(
                Theme.of(context).brightness == Brightness.dark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              _buildLoginCard()
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.themeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings,
                size: 64,
                color: widget.themeColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Access ${widget.roleName} Module',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue',
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _userIdController,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'User ID',
                hintStyle: TextStyle(color: subtitleColor),
                prefixIcon: const Icon(Icons.person, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter User ID' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: textColor),
              onFieldSubmitted: (_) => _login(),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(color: subtitleColor),
                prefixIcon: const Icon(Icons.lock, color: Color(0xFF94A3B8)),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 8),
                Text(
                  'Secure Access. Authorized Personnel Only.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _isCheckingUpdate ? null : _manualCheckUpdate,
                  icon: _isCheckingUpdate
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF64748B),
                          ),
                        )
                      : const Icon(
                          Icons.system_update_alt_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                  label: Text(
                    _isCheckingUpdate ? 'Checking for updates...' : 'Check for app updates',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
