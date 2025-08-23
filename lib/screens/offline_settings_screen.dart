import 'package:flutter/material.dart';
import '../services/offline_service.dart';
import '../services/connectivity_service.dart';

class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  Map<String, int> _cacheInfo = {};
  DateTime? _lastSync;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    try {
      final cacheInfo = await OfflineService.getCacheInfo();
      final lastSync = await OfflineService.getLastSync();
      
      if (mounted) {
        setState(() {
          _cacheInfo = cacheInfo;
          _lastSync = lastSync;
          _isOnline = ConnectivityService().isConnected;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheInfo = {
            'lessons': 0,
            'assessments': 0,
            'progress': 0,
            'profile': 0,
            'total': 0,
          };
          _lastSync = null;
          _isOnline = true; // Default to online if there's an error
        });
      }
    }
  }

  Future<void> _clearCache() async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Clear Cache'),
          content: const Text('This will remove all cached data. You\'ll need to download data again when online.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await OfflineService.clearCache();
        await _loadCacheInfo();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cache cleared successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing cache: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Offline Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: Color(0xFF1D1D1F),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1D1F),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connection Status
              _buildStatusCard(),
              
              const SizedBox(height: 20),
              
              // Cache Information
              _buildCacheInfoCard(),
              
              const SizedBox(height: 20),
              
              // Actions
              _buildActionsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: _isOnline ? Colors.green : const Color(0xFFFF9500),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Connection Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isOnline ? 'You are currently online' : 'You are currently offline',
            style: TextStyle(
              fontSize: 16,
              color: _isOnline ? Colors.green : const Color(0xFFFF9500),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheInfoCard() {
    final totalSize = _cacheInfo['total'] ?? 0;
    final hasData = totalSize > 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage_rounded,
                color: const Color(0xFF007AFF),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Cached Data',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (hasData) ...[
            _buildCacheItem('Lessons', _cacheInfo['lessons'] ?? 0),
            const SizedBox(height: 8),
            _buildCacheItem('Assessments', _cacheInfo['assessments'] ?? 0),
            const SizedBox(height: 8),
            _buildCacheItem('Student Progress', _cacheInfo['progress'] ?? 0),
            const SizedBox(height: 8),
            _buildCacheItem('User Profile', _cacheInfo['profile'] ?? 0),
            const SizedBox(height: 16),
            Divider(color: const Color(0xFFE5E5E7)),
            const SizedBox(height: 8),
            _buildCacheItem('Total', totalSize, isTotal: true),
          ] else ...[
            Text(
              'No data cached yet',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF86868B),
              ),
            ),
          ],
          
          if (_lastSync != null) ...[
            const SizedBox(height: 16),
            Divider(color: const Color(0xFFE5E5E7)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.sync_rounded,
                  color: const Color(0xFF86868B),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Last synced: ${_formatLastSync(_lastSync)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF86868B),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCacheItem(String label, int size, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? const Color(0xFF1D1D1F) : const Color(0xFF86868B),
          ),
        ),
        Text(
          isTotal ? '${size} bytes' : '$size bytes',
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            color: isTotal ? const Color(0xFF007AFF) : const Color(0xFF86868B),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings_rounded,
                color: const Color(0xFF007AFF),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_cacheInfo['total'] ?? 0) > 0 ? _clearCache : null,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Clear All Cached Data'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Clearing cache will remove all offline data. You\'ll need to download data again when online.',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF86868B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
