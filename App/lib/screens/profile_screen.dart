import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/analytics_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _occupationController = TextEditingController();
  final _authService = AuthService();
  final _analyticsService = AnalyticsService();
  
  String? _photoUrl;
  String? _provider;
  String? _memberSince;
  int _formsCompleted = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime? _dateOfBirth;
  String? _gender;
  List<Map<String, String>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nationalityController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    
    try {
      final userData = await _authService.getCurrentUser();
      final stats = await _analyticsService.getDashboardStats();
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        if (userData != null) {
          _nameController.text = userData['name'] ?? '';
          _nicknameController.text = userData['nickname'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _addressController.text = userData['address'] ?? '';
          _nationalityController.text = userData['nationality'] ?? '';
          _occupationController.text = userData['occupation'] ?? '';
          _photoUrl = userData['photoUrl'];
          _provider = userData['provider'];
          _gender = userData['gender'];
          
          // Load date of birth
          if (userData['dateOfBirth'] != null) {
            try {
              _dateOfBirth = DateTime.parse(userData['dateOfBirth']);
            } catch (e) {
              _dateOfBirth = null;
            }
          }
          
          // Load emergency contacts - support both old format (single) and new format (list)
          if (userData['emergencyContacts'] != null) {
            try {
              final contacts = userData['emergencyContacts'] as List;
              _emergencyContacts = contacts.map((contact) {
                if (contact is Map) {
                  return {
                    'name': contact['name']?.toString() ?? '',
                    'phone': contact['phone']?.toString() ?? '',
                  };
                }
                return {'name': '', 'phone': ''};
              }).toList();
            } catch (e) {
              _emergencyContacts = [];
            }
          } else if (userData['emergencyContactName'] != null || userData['emergencyContactPhone'] != null) {
            // Migrate old single contact format to new list format
            final name = userData['emergencyContactName']?.toString() ?? '';
            final phone = userData['emergencyContactPhone']?.toString() ?? '';
            if (name.isNotEmpty || phone.isNotEmpty) {
              _emergencyContacts = [
                {'name': name, 'phone': phone}
              ];
            }
          }
        }
        
        _formsCompleted = stats['completed'] ?? 0;
        
        final memberSinceStr = prefs.getString('member_since');
        if (memberSinceStr != null) {
          final memberSince = DateTime.parse(memberSinceStr);
          _memberSince = '${memberSince.year}';
        } else {
          _memberSince = DateTime.now().year.toString();
        }
      });
    } catch (e) {
      print('Error loading profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _authService.updateUserProfile({
        'name': _nameController.text.trim(),
        'nickname': _nicknameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'gender': _gender,
        'address': _addressController.text.trim(),
        'nationality': _nationalityController.text.trim(),
        'occupation': _occupationController.text.trim(),
        'emergencyContacts': _emergencyContacts,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _showAddEmergencyContactDialog({int? index}) async {
    String? initialName;
    String? initialPhone;
    
    // If editing, get initial values
    if (index != null && index < _emergencyContacts.length) {
      initialName = _emergencyContacts[index]['name'] ?? '';
      initialPhone = _emergencyContacts[index]['phone'] ?? '';
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _EmergencyContactDialog(
        initialName: initialName,
        initialPhone: initialPhone,
        isEditing: index != null,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (index != null && index < _emergencyContacts.length) {
          // Update existing contact
          _emergencyContacts[index] = result;
        } else {
          // Add new contact
          _emergencyContacts.add(result);
        }
      });
    }
  }

  void _removeEmergencyContact(int index) {
    setState(() {
      _emergencyContacts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: theme.colorScheme.primary,
                            backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                                ? NetworkImage(_photoUrl!)
                                : null,
                            child: _photoUrl == null || _photoUrl!.isEmpty
                                ? Text(
                                    _getInitials(_nameController.text),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          if (_provider != null)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.dividerColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _provider == 'google'
                                      ? Icons.g_mobiledata
                                      : Icons.facebook,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Signed in with ${_provider == 'google' ? 'Google' : _provider == 'facebook' ? 'Facebook' : 'Email'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Nickname Field
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: 'Nickname (Optional)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      readOnly: _provider != null, // Don't allow editing if signed in with OAuth
                    ),
                    const SizedBox(height: 16),
                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date of Birth Field
                    InkWell(
                      onTap: _selectDateOfBirth,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _dateOfBirth != null
                              ? DateFormat('MMM dd, yyyy').format(_dateOfBirth!)
                              : 'Select date',
                          style: _dateOfBirth != null
                              ? Theme.of(context).textTheme.bodyLarge
                              : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                                  ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Gender Field
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(
                        labelText: 'Gender (Optional)',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                        DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _gender = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      keyboardType: TextInputType.streetAddress,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Address (Optional)',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nationality Field
                    TextFormField(
                      controller: _nationalityController,
                      decoration: const InputDecoration(
                        labelText: 'Nationality/Country (Optional)',
                        prefixIcon: Icon(Icons.flag_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Occupation Field
                    TextFormField(
                      controller: _occupationController,
                      decoration: const InputDecoration(
                        labelText: 'Occupation/Job Title (Optional)',
                        prefixIcon: Icon(Icons.work_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Emergency Contact Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Emergency Contacts',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_emergencyContacts.isNotEmpty)
                          TextButton.icon(
                            onPressed: () => _showAddEmergencyContactDialog(),
                            icon: const Icon(Icons.add, size: 20),
                            label: const Text('Add'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Emergency Contacts List
                    if (_emergencyContacts.isEmpty)
                      InkWell(
                        onTap: () => _showAddEmergencyContactDialog(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.dividerColor,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add Emergency Contact',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          ...List.generate(
                            _emergencyContacts.length,
                            (index) {
                              final contact = _emergencyContacts[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    child: Icon(
                                      Icons.contact_emergency_outlined,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  title: Text(
                                    contact['name'] ?? '',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  subtitle: Text(
                                    contact['phone'] ?? '',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined),
                                        onPressed: () => _showAddEmergencyContactDialog(index: index),
                                        tooltip: 'Edit',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () => _removeEmergencyContact(index),
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),
                    // Stats Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '$_formsCompleted',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Forms Completed',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: theme.dividerColor,
                            ),
                            Column(
                              children: [
                                Text(
                                  _memberSince ?? '2024',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Member Since',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.brightness == Brightness.dark
                              ? theme.colorScheme.surface
                              : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EmergencyContactDialog extends StatefulWidget {
  final String? initialName;
  final String? initialPhone;
  final bool isEditing;

  const _EmergencyContactDialog({
    this.initialName,
    this.initialPhone,
    required this.isEditing,
  });

  @override
  State<_EmergencyContactDialog> createState() => _EmergencyContactDialogState();
}

class _EmergencyContactDialogState extends State<_EmergencyContactDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit Emergency Contact' : 'Add Emergency Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _handleSubmit,
          style: FilledButton.styleFrom(
            backgroundColor: Color.lerp(Colors.black, Colors.white, 0.2), // 20% white, 80% black
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white, width: 1), // White outline
          ),
          child: Text(widget.isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}

