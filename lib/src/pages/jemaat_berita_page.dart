import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/models.dart';
import '../core/session_controller.dart';

class JemaatBeritaPage extends StatefulWidget {
  const JemaatBeritaPage({super.key, required this.session});

  final SessionController session;

  @override
  State<JemaatBeritaPage> createState() => _JemaatBeritaPageState();
}

class _JemaatBeritaPageState extends State<JemaatBeritaPage> {
  late final ApiClient _api;

  List<Map<String, dynamic>> _berita = <Map<String, dynamic>>[];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _api = widget.session.apiClient;
    _loadBerita();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBerita() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = widget.session.token;
      if (token == null || token.isEmpty) {
        throw const ApiError(message: 'Token tidak tersedia');
      }

      // Load documentations/blog articles
      await _api.me(token); // Placeholder validasi token/session
      // For now, return empty list with message
      _berita = <Map<String, dynamic>>[];
    } on ApiError catch (error) {
      _error =
          '${error.message}${error.traceId != null ? ' (trace: ${error.traceId})' : ''}';
    } catch (_) {
      _error = 'Gagal memuat berita';
    }

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBerita {
    if (_searchQuery.isEmpty) {
      return _berita;
    }
    return _berita
        .where(
          (item) =>
              (item['title'] as String?)?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false,
        )
        .toList();
  }

  String _formatTanggal(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(
        dateStr,
      ).toUtc().add(const Duration(hours: 8));
      const bulan = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      final hari = date.day.toString().padLeft(2, '0');
      final jam = date.hour.toString().padLeft(2, '0');
      final menit = date.minute.toString().padLeft(2, '0');
      return '$hari ${bulan[date.month - 1]} ${date.year} $jam:$menit WITA';
    } catch (_) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Berita & Informasi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Cari berita...',
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                if (_error != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: _filteredBerita.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.newspaper,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _berita.isEmpty
                                    ? 'Belum ada berita'
                                    : 'Tidak ada hasil pencarian',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredBerita.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final berita = _filteredBerita[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  (berita['title'] as String?) ?? 'Tanpa Judul',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (berita['description'] as String?) ??
                                            '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTanggal(
                                          berita['created_at'] as String?,
                                        ),
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () {
                                  _showBeritaDetail(berita);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  void _showBeritaDetail(Map<String, dynamic> berita) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          (berita['title'] as String?) ?? 'Berita',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTanggal(berita['created_at'] as String?),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(berita['content'] as String? ?? '-'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
