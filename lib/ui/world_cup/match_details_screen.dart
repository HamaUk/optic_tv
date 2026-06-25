import 'package:flutter/material.dart';
import '../../services/world_cup_service.dart';
import '../../core/theme.dart';
import 'dart:ui';

class MatchDetailsScreen extends StatefulWidget {
  final String eventId;
  final String homeTeam;
  final String awayTeam;
  final String? homeFlag;
  final String? awayFlag;

  const MatchDetailsScreen({
    super.key,
    required this.eventId,
    required this.homeTeam,
    required this.awayTeam,
    this.homeFlag,
    this.awayFlag,
  });

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final summary = await WorldCupService.fetchMatchSummary(widget.eventId);
    if (mounted) {
      setState(() {
        _summary = summary;
        _loading = false;
      });
    }
  }

  Widget _glassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${widget.homeTeam} vs ${widget.awayTeam}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _summary == null
              ? const Center(child: Text('Data not available', style: TextStyle(color: Colors.white)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final gameInfo = _summary?['gameInfo'];
    final venue = gameInfo?['venue'];
    final keyEvents = _summary?['keyEvents'] as List<dynamic>? ?? [];
    final rosters = _summary?['rosters'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STADIUM INFO
          if (venue != null) ...[
            Text('یاریگا (Stadium)', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _glassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.stadium_rounded, color: AppTheme.primaryGold, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(venue['fullName'] ?? 'Unknown Stadium', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (venue['address'] != null)
                          Text('${venue['address']['city'] ?? ''}, ${venue['address']['country'] ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          // LIVE COMMENTARY / EVENTS
          if (keyEvents.isNotEmpty) ...[
            Text('ڕووداوەکان (Events)', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _glassContainer(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: keyEvents.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final event = keyEvents[index];
                  final text = event['text'] ?? '';
                  final time = event['clock']?['displayValue'] ?? event['time']?['displayValue'] ?? '';
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(time, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(text, style: const TextStyle(color: Colors.white)),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
          ],

          // LINEUPS
          if (rosters.isNotEmpty) ...[
            Text('پێکهاتەکان (Lineups)', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rosters.map((teamRoster) {
                final roster = teamRoster['roster'] as List<dynamic>? ?? [];
                final formation = teamRoster['formation'] ?? '';
                final isHome = teamRoster['homeAway'] == 'home';
                final teamName = isHome ? widget.homeTeam : widget.awayTeam;

                return Expanded(
                  child: _glassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(teamName, style: const TextStyle(color: AppTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
                        if (formation.isNotEmpty)
                          Text('Formation: $formation', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                        const SizedBox(height: 16),
                        ...roster.where((p) => p['starter'] == true).map((player) {
                          final pName = player['athlete']?['displayName'] ?? 'Unknown';
                          final jersey = player['jersey'] ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(width: 24, child: Text(jersey, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12))),
                                Expanded(child: Text(pName, style: const TextStyle(color: Colors.white, fontSize: 14))),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
