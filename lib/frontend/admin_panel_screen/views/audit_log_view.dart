import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Or your preferred DI method
import 'dart:convert';                     // For jsonDecode
import 'package:intl/intl.dart';               // For date formatting

// Assuming your APIRepository is in this path
import '../../../core/repositories/API.dart';

class AuditLogScreen extends StatefulWidget {
  // Accept the APIRepository instance via constructor
  // final APIRepository apiRepository;

  // Or, if using Provider/GetIt, you might not need to pass it explicitly
  const AuditLogScreen({
    super.key,
    // required this.apiRepository, // Uncomment if passing via constructor
  });

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _logEntries = [];

  // --- Access APIRepository ---
  // Use late if you are sure it will be initialized in initState via Provider/GetIt
  // late final APIRepository _apiRepository;
  // Or access directly via widget if passed in constructor
  // APIRepository get _apiRepository => widget.apiRepository;


  @override
  void initState() {
    super.initState();
    // --- Initialize APIRepository Access ---
    // If using Provider:
    // _apiRepository = context.read<APIRepository>();
    // If using GetIt:
    // _apiRepository = GetIt.I<APIRepository>();
    // If passed via constructor, it's accessed via widget.apiRepository

    // --- End Initialization ---

    // Fetch logs immediately
    // Use WidgetsBinding to ensure context is available for Provider.read if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure context is mounted before accessing Provider
      if (mounted) {
        _fetchAuditLog();
      }
    });
  }

  Future<void> _fetchAuditLog() async {
    // --- Access APIRepository Instance ---
    // Make sure you have access to the instance here.
    // Using Provider as an example:
    if (!mounted) return; // Check mount status before accessing context
    final apiRepository = Provider.of<APIRepository>(context, listen: false);
    // --- End Access ---

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _logEntries = []; // Clear previous entries
    });

    try {
      // --- USE THE REPOSITORY METHOD ---
      final String? logData = await apiRepository.fetchAuditLog();
      // --- END USE ---

      if (!mounted) return; // Check again after async operation

      if (logData != null) {
        // Process the logData string (split lines, decode JSON)
        final List<Map<String, dynamic>> entries = [];
        final lines = logData.split('\n');
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            try {
              final Map<String, dynamic> entry = jsonDecode(line.trim());
              entries.add(entry);
            } catch (e) {
              // Consider logging this more formally if needed
              debugPrint("Error decoding JSON line: $line - Error: $e");
              // Optionally add a placeholder for bad lines
              // entries.add({'error': 'Failed to decode line', 'raw': line});
            }
          }
        }
        setState(() {
          _logEntries = entries;
          _isLoading = false;
        });
      } else {
        // Handle the case where fetchAuditLog returned null (error occurred)
        setState(() {
          // The repository method handles specific errors, so provide a general message
          _error = "Failed to load audit log. Check permissions or server status.";
          _isLoading = false;
        });
      }
    } catch (e) { // Catch potential errors *thrown* by fetchAuditLog (if any)
      if (!mounted) return;
      debugPrint("Error calling fetchAuditLog in screen: $e");
      setState(() {
        _error = "An unexpected error occurred while fetching the log.";
        _isLoading = false;
      });
    }
  }

  String _formatTimestamp(String? isoTimestamp) {
    if (isoTimestamp == null) return 'N/A';
    try {
      // Handle potential 'Z' at the end for UTC and ensure proper parsing
      final dt = DateTime.parse(isoTimestamp.endsWith('Z')
          ? isoTimestamp.replaceAll('Z', '+00:00') // More robust replacement
          : isoTimestamp);
      // Format to local time for display
      return DateFormat('yyyy-MM-dd HH:mm:ss (zzz)').format(dt.toLocal()); // Added timezone info
    } catch (e) {
      debugPrint("Error parsing timestamp '$isoTimestamp': $e");
      return isoTimestamp; // Return original if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchAuditLog, // Disable while loading
            tooltip: 'Refresh Log',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Added Column for refresh button
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                onPressed: _fetchAuditLog,
              ),
            ],
          ),
        ),
      );
    }

    if (_logEntries.isEmpty) {
      return const Center(child: Text('Audit log is empty.'));
    }

    // Display logs in reverse chronological order (newest first)
    final reversedEntries = _logEntries.reversed.toList();

    return RefreshIndicator( // Added pull-to-refresh
      onRefresh: _fetchAuditLog,
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: reversedEntries.length,
        itemBuilder: (context, index) {
          final entry = reversedEntries[index];

          // Safely access map keys
          final timestamp = _formatTimestamp(entry['ts'] as String?);
          final userId = entry['uid']?.toString() ?? 'anonymous'; // Handle null and non-string types
          final action = entry['act']?.toString() ?? 'unknown_action';
          final target = entry['target']?.toString() ?? '-';
          final status = entry['status']?.toString() ?? 'unknown';
          final ip = entry['ip']?.toString() ?? 'unknown_ip';
          final extra = entry['extra'] as Map<String, dynamic>? ?? {}; // Ensure it's a map

          Color statusColor = Colors.grey;
          IconData statusIcon = Icons.info_outline;

          switch (status.toLowerCase()) {
            case 'success':
              statusColor = Colors.green.shade700;
              statusIcon = Icons.check_circle_outline;
              break;
            case 'denied':
              statusColor = Colors.orange.shade800;
              statusIcon = Icons.block_flipped; // Changed icon
              break;
            case 'error':
              statusColor = Theme.of(context).colorScheme.error;
              statusIcon = Icons.error_outline;
              break;
          }

          return Card(
            elevation: 2.0,
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: ListTile(
              leading: Tooltip( // Added Tooltip for status icon
                message: status,
                child: Icon(statusIcon, color: statusColor, size: 28),
              ),
              title: Text(
                '$action ${target != '-' ? 'on "$target"' : ''}', // Improved formatting
                style: const TextStyle(fontWeight: FontWeight.w600), // Slightly bolder
                overflow: TextOverflow.ellipsis, // Prevent long text overflow
              ),
              subtitle: Padding( // Added padding for better spacing
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Time: $timestamp'),
                    Text('User: $userId'),
                    Text('IP: $ip'),
                    // Text('Status: $status', style: TextStyle(color: statusColor)), // Status shown by icon/tooltip
                    if (extra.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        // Display extra info concisely and handle non-string values
                        child: Text(
                          'Details: ${jsonEncode(extra, // Pretty print for readability
                              toEncodable: (Object? value) => value.toString() // Handle non-serializable objects
                          )}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          maxLines: 2, // Limit lines shown initially
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Remove isThreeLine if not needed, adjust based on content
              // isThreeLine: true,
              // Optional: Add onTap for expansion or details view
              // onTap: () {
              //   // Show detailed view in a dialog or new screen
              //   _showLogEntryDetails(context, entry);
              // },
            ),
          );
        },
      ),
    );
  }

// Optional: Helper method to show details in a dialog
// void _showLogEntryDetails(BuildContext context, Map<String, dynamic> entry) {
//   showDialog(
//     context: context,
//     builder: (context) => AlertDialog(
//       title: Text('Log Entry Details'),
//       content: SingleChildScrollView(
//         child: SelectableText(JsonEncoder.withIndent('  ').convert(entry)), // Pretty print JSON
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: Text('Close'),
//         ),
//       ],
//     ),
//   );
// }

} // End of _AuditLogScreenState class