import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import 'package:flutter/material.dart';
import '../../services/world_cup_service.dart';

class TeamDetailsScreen extends ConsumerStatefulWidget {
  final String teamId;
  final String teamName;
  final String teamFlag;

  const TeamDetailsScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamFlag,
  });

  @override
  ConsumerState<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends ConsumerState<TeamDetailsScreen> {
  bool _loading = true;
  List<dynamic> _roster = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final roster = await WorldCupService.fetchTeamRoster(widget.teamId);
    if (mounted) {
      setState(() {
        _roster = roster;
        _loading = false;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final s = AppStrings(locale);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.teamName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Hero(
            tag: 'team_logo_${widget.teamId}',
            child: Image.network(widget.teamFlag, height: 100, fit: BoxFit.contain,
              errorBuilder: (_,__,___) => const Icon(Icons.flag, size: 100, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 20),
          const Text(s.wcSquadRoster, style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
              : _roster.isEmpty
                ? const Center(child: Text(s.wcNoRosterData, style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _roster.length,
                    itemBuilder: (context, index) {
                      final player = _roster[index];
                      final name = player['fullName'] ?? '';
                      final pos = player['position']?['abbreviation'] ?? '';
                      final jersey = player['jersey'] ?? '';
                      final headshot = player['headshot']?['href'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              alignment: Alignment.center,
                              child: Text(jersey, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 12),
                            ClipOval(
                              child: headshot.isNotEmpty
                                ? Image.network(headshot, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.person, color: Colors.white54, size: 40))
                                : const Icon(Icons.person, color: Colors.white54, size: 40),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(pos, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}




