import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_navigation.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatefulWidget {
  final void Function(String)? onThemeChanged;
  
  const SettingsScreen({super.key, this.onThemeChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentTheme = 'light';
  final _authService = AuthService();
  final _analyticsService = AnalyticsService();
  
  Map<String, dynamic>? _userData;
  int _formsCompleted = 0;
  String? _memberSince;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _loadProfileData();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('theme') ?? 'light';
    });
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoadingProfile = true);
    try {
      final userData = await _authService.getCurrentUser();
      final stats = await _analyticsService.getDashboardStats();
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _userData = userData;
        _formsCompleted = stats['completed'] ?? 0;
        
        final memberSinceStr = prefs.getString('member_since');
        if (memberSinceStr != null) {
          final memberSince = DateTime.parse(memberSinceStr);
          _memberSince = '${memberSince.year}';
        } else {
          _memberSince = '2024';
        }
      });
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      setState(() => _isLoadingProfile = false);
    }
  }
  
  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _changeTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    setState(() {
      _currentTheme = theme;
    });
    
    // Notify root app to update theme immediately
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(theme);
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Theme changed successfully!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: 100.0, // Add bottom padding for navigation
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/dashboard');
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Settings',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Profile Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _isLoadingProfile
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Row(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: theme.colorScheme.primary,
                                  backgroundImage: _userData?['photoUrl'] != null &&
                                          (_userData!['photoUrl'] as String).isNotEmpty
                                      ? NetworkImage(_userData!['photoUrl'] as String)
                                      : null,
                                  child: _userData?['photoUrl'] == null ||
                                          (_userData!['photoUrl'] as String).isEmpty
                                      ? Text(
                                          _getInitials(_userData?['name'] as String?),
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userData?['name'] as String? ?? 'User',
                                        style: theme.textTheme.titleLarge,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _userData?['email'] as String? ?? 'No email',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$_formsCompleted Forms Completed • Member since $_memberSince',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Settings Sections
                  _SettingsSection(
                    title: 'Account',
                    items: [
                      _SettingsItem(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        onTap: () async {
                          await context.push('/profile');
                          // Reload profile data after returning from profile screen
                          _loadProfileData();
                        },
                      ),
                      _SettingsItem(
                        icon: Icons.lock_outline,
                        title: 'Security',
                        onTap: () {
                          context.push('/security');
                        },
                      ),
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        onTap: () {
                          context.push('/notifications');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _SettingsSection(
                    title: 'Appearance',
                    items: [
                      _SettingsItem(
                        icon: Icons.palette_outlined,
                        title: 'Theme',
                        trailing: SizedBox(
                          width: 200,
                          child: _ThemeSelector(
                            currentTheme: _currentTheme,
                            onThemeChanged: _changeTheme,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _SettingsSection(
                    title: 'Support',
                    items: [
                      _SettingsItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Help & Support'),
                              content: const Text(
                                'For support, please contact us at:\n\nsupport@fillora.in\n\nWe are here to help you!',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      _SettingsItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('About Fillora.in'),
                              content: const Text(
                                'Fillora.in - AI-powered Form Assistant\n\nVersion 1.0.0 (Beta)\n\nYour compassionate partner for effortless forms.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                        
                        if (shouldLogout == true && mounted) {
                          await _authService.signOut();
                          if (mounted) {
                            context.go('/signin');
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Logout', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.red, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Reduced from 100 since we have bottom padding
                ],
              ),
            ),
            // Bottom Navigation - Fixed position at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BottomNavigation(currentRoute: '/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(children: items),
        ),
      ],
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}

class _ThemeSelector extends StatefulWidget {
  final String currentTheme;
  final Function(String) onThemeChanged;

  const _ThemeSelector({
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  State<_ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<_ThemeSelector> {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> themes = [
    {'name': 'light', 'color': Colors.blue, 'label': 'Light'},
    {'name': 'dark', 'color': Colors.grey, 'label': 'Dark'},
    {'name': 'green', 'color': Colors.green, 'label': 'Green'},
    {'name': 'purple', 'color': Colors.purple, 'label': 'Purple'},
    {'name': 'orange', 'color': Colors.orange, 'label': 'Orange'},
    {'name': 'pink', 'color': Colors.pink, 'label': 'Pink'},
  ];

  @override
  void initState() {
    super.initState();
    // Scroll to selected theme after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTheme();
    });
  }

  @override
  void didUpdateWidget(_ThemeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to selected theme when theme changes
    if (oldWidget.currentTheme != widget.currentTheme) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedTheme();
      });
    }
  }

  void _scrollToSelectedTheme() {
    if (!_scrollController.hasClients) return;
    
    final selectedIndex = themes.indexWhere(
      (theme) => theme['name'] == widget.currentTheme,
    );
    
    if (selectedIndex >= 0) {
      // Wait a bit to ensure the scroll controller is fully initialized and layout is complete
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!_scrollController.hasClients) return;
        
        // Calculate scroll position: each item is 40px wide + 8px padding (except last)
        final itemWidth = 40.0;
        final itemPadding = 8.0;
        final screenWidth = MediaQuery.of(context).size.width;
        
        // Calculate the position of the selected item's left edge
        final itemLeftPosition = selectedIndex * (itemWidth + itemPadding);
        
        // Calculate scroll position to center the selected item in the viewport
        // We want the center of the item to be at the center of the screen
        double scrollPosition = itemLeftPosition + (itemWidth / 2) - (screenWidth / 2);
        
        // Get the maximum scroll extent
        final maxScroll = _scrollController.position.maxScrollExtent;
        
        // Clamp the scroll position to valid range
        // This ensures consistent behavior for all themes (orange, pink, etc.)
        scrollPosition = scrollPosition.clamp(0.0, maxScroll);
        
        _scrollController.animateTo(
          scrollPosition,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: themes.length,
        itemBuilder: (context, index) {
          final theme = themes[index];
          final isSelected = widget.currentTheme == theme['name'];
          return Padding(
            padding: EdgeInsets.only(right: index < themes.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => widget.onThemeChanged(theme['name'] as String),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme['color'] as Color,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

