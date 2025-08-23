import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/offline_service.dart';

class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;
  Map<String, dynamic> _offlineInfo = {};

  @override
  void initState() {
    super.initState();
    _loadOfflineInfo();
    _checkConnectivity();
  }

  Future<void> _loadOfflineInfo() async {
    try {
      final cacheInfo = await OfflineService.getCacheInfo();
      final lastSync = await OfflineService.getLastSync();
      final isStale = await OfflineService.isDataStale();
      
      if (mounted) {
        setState(() {
          _offlineInfo = {
            'hasData': (cacheInfo['total'] ?? 0) > 0,
            'lessonsCount': cacheInfo['lessons'] ?? 0,
            'lastSync': lastSync?.toIso8601String(),
            'isStale': isStale,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _offlineInfo = {
            'hasData': false,
            'lessonsCount': 0,
            'lastSync': null,
            'isStale': true,
          };
        });
      }
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final isOnline = ConnectivityService().isConnected;
      if (mounted && _isOnline != isOnline) {
        setState(() {
          _isOnline = isOnline;
        });
        await _loadOfflineInfo();
      }
    } catch (e) {
      // If there's an error, assume online
      if (mounted && _isOnline != true) {
        setState(() {
          _isOnline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnline) {
      return const SizedBox.shrink(); // Don't show anything when online
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9500).withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFFF9500).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: const Color(0xFFFF9500),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You\'re offline',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF9500),
                  ),
                ),
                if (_offlineInfo['hasData'] == true)
                  Text(
                    'Showing cached data from ${_offlineInfo['lastSync'] != null ? _formatLastSync(_offlineInfo['lastSync']) : 'previous session'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFFFF9500).withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (_offlineInfo['hasData'] == true)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_offlineInfo['lessonsCount']} lessons cached',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFF9500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatLastSync(String? lastSync) {
    if (lastSync == null) return 'previous session';
    
    try {
      final dateTime = DateTime.parse(lastSync);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'previous session';
    }
  }
}
