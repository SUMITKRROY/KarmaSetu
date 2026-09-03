import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/storage/table/profile_table.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  final bool isTab;
  const ProfilePage({super.key, this.isTab = true});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileTable _profileTable = ProfileTable();
  Map<String, dynamic>? _localProfile;
  bool _isLoadingLocal = true;

  @override
  void initState() {
    super.initState();
    _loadFromLocalStorage();
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final list = await _profileTable.getAll();
      if (mounted) {
        setState(() {
          _localProfile = list.isNotEmpty ? list.first : null;
          _isLoadingLocal = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLocal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
        } else if (state is AuthAuthenticated) {
          _loadFromLocalStorage();
        }
      },
      builder: (context, state) {
        final authUser = (state is AuthAuthenticated) ? state.user : null;

        // Data loaded directly from our SQLite DatabaseHelper via ProfileTable
        final name = (_localProfile?[ProfileTable.name]?.toString().isNotEmpty == true)
            ? _localProfile![ProfileTable.name].toString()
            : (authUser?.name.isNotEmpty == true ? authUser!.name : 'Test Employee');

        final email = (_localProfile?[ProfileTable.email]?.toString().isNotEmpty == true)
            ? _localProfile![ProfileTable.email].toString()
            : (authUser?.email.isNotEmpty == true ? authUser!.email : 'employee@test.com');

        final employeeId = (_localProfile?[ProfileTable.employeeId]?.toString().isNotEmpty == true)
            ? _localProfile![ProfileTable.employeeId].toString()
            : (authUser?.employeeId.isNotEmpty == true ? authUser!.employeeId : 'EMP001');

        final role = (_localProfile?[ProfileTable.role]?.toString().isNotEmpty == true)
            ? _localProfile![ProfileTable.role].toString()
            : (authUser?.role.isNotEmpty == true ? authUser!.role : 'employee');

        final department = (_localProfile?[ProfileTable.department]?.toString().isNotEmpty == true)
            ? _localProfile![ProfileTable.department].toString()
            : (authUser?.department.isNotEmpty == true ? authUser!.department : 'Engineering');

        final site = (_localProfile?[ProfileTable.site]?.toString().isNotEmpty == true)
            ? _localProfile![ProfileTable.site].toString()
            : (authUser?.site.isNotEmpty == true ? authUser!.site : 'Bangalore');

        final uid = (_localProfile?[ProfileTable.uid]?.toString().isNotEmpty == true)
            ? _localProfile![ProfileTable.uid].toString()
            : (authUser?.uid ?? '');

        final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Profile'),
            leading: widget.isTab
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Reload from Local DB',
                onPressed: _loadFromLocalStorage,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                tooltip: 'Logout',
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadFromLocalStorage,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. Profile Header Avatar
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Color(0xFF8CD4B4),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              initials.isEmpty ? 'KS' : initials,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF17211C),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Color(0xFF3355A6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Name & Role
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          role.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Active Status & DatabaseHelper Synced Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 8, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Active User',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.storage_rounded, size: 12, color: Color(0xFF2563EB)),
                              SizedBox(width: 4),
                              Text(
                                'Local DB Synced',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. User Information Card (from SQLite DatabaseHelper)
                    _buildSectionCard(
                      title: 'User Information (Local SQLite)',
                      icon: Icons.badge_outlined,
                      children: [
                        _buildInfoRow('EMPLOYEE ID', employeeId),
                        _buildInfoRow('NAME', name),
                        _buildInfoRow('ROLE', role.toUpperCase()),
                        _buildInfoRow('DEPARTMENT', department),
                        _buildInfoRow('SITE', site, isLast: true),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Contact Information Card
                    _buildSectionCard(
                      title: 'Contact Information',
                      icon: Icons.contact_mail_outlined,
                      children: [
                        _buildContactRow(
                          icon: Icons.mail_outline_rounded,
                          label: 'EMAIL',
                          value: email,
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Local Storage SQLite Details
                    _buildSectionCard(
                      title: 'Local Storage Details (DatabaseHelper)',
                      icon: Icons.data_object_outlined,
                      children: [
                        _buildInfoRow('TABLE', ProfileTable.tableName),
                        if (uid.isNotEmpty) _buildInfoRow('LOCAL UID', uid),
                        _buildInfoRow(
                          'STATUS',
                          _isLoadingLocal
                              ? 'Loading local DB...'
                              : (_localProfile != null ? 'Synced from SQLite' : 'Default / In-Memory'),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _showLogoutDialog(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        'Logout',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out of KarmaSetu? Local cache will be cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.border.withAlpha(80)),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FE),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF3355A6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
