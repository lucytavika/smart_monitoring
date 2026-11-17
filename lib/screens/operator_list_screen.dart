import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OperatorListScreen extends StatefulWidget {
  final String userRole;

  const OperatorListScreen({super.key, required this.userRole});

  @override
  State<OperatorListScreen> createState() => _OperatorListScreenState();
}

class _OperatorListScreenState extends State<OperatorListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List _operatorList = [];
  bool _isLoading = true;
  late final RealtimeChannel _operatorChannel;
  
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchOperators();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    supabase.removeChannel(_operatorChannel);
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    try {
      final response = await supabase
          .from('operators')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _operatorList = List.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealtimeSubscription() {
    _operatorChannel = supabase
        .channel('public:operators')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'operators',
          callback: (payload) {
            _fetchOperators(); // Otomatis refresh saat ada perubahan data di Supabase
          },
        )
        .subscribe();
  }

  Future<void> _hapusOperator(dynamic rawId) async {
    try {
      await supabase.from('operators').delete().eq('id', rawId);
      await _fetchOperators();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Operator berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus operator: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter daftar berdasarkan kolom is_online di database
    final filteredList = _operatorList.where((op) {
      final bool isOnline = op['is_online'] == true;

      if (_selectedFilter == 'Online') {
        return isOnline;
      } else if (_selectedFilter == 'Offline') {
        return !isOnline;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Operator Terdaftar',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Color(0xFF2E7CF6)),
                    onPressed: _fetchOperators,
                    tooltip: 'Muat Ulang',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pemantauan status login operator secara real-time',
              style: TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),

            Row(
              children: ['Semua', 'Online', 'Offline'].map((filter) {
                bool isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2E7CF6),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7CF6)))
                  : filteredList.isEmpty
                      ? const Center(
                          child: Text('Tidak ada operator yang sesuai.', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
                        )
                      : ListView.builder(
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final op = filteredList[index];
                            
                            // 100% BERPATOKAN PADA DATABASE: Membaca kolom boolean 'is_online'
                            final bool isOnline = op['is_online'] == true;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300, width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: const Color(0xFF2E7CF6).withValues(alpha: 0.15),
                                    child: const Icon(Icons.person, color: Color(0xFF2E7CF6)),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              op['nama'] ?? 'Tanpa Nama',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isOnline ? 'Online' : 'Offline',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${op['nomor_id'] ?? '-'}',
                                          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Email: ${op['email'] ?? '-'}',
                                          style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () => _hapusOperator(op['id']),
                                    tooltip: 'Hapus Operator',
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}