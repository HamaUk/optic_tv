part of '../admin_screen.dart';

extension _AdminAnalyticsTabExt on _AdminScreenState {
  Widget _buildAnalyticsTab() {
    final analyticsService = AnalyticsService();
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.backgroundBlack, AppTheme.surfaceGray.withValues(alpha: 0.45)],
        ),
      ),
      child: StreamBuilder<AnalyticsDashboardData>(
        stream: analyticsService.getDashboardDataStream(),
        builder: (context, snap) {
          final data = snap.data ?? AnalyticsDashboardData.empty();
          
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // 3 STATS TILES (TODAY)
              Text('Today', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final tiles = [
                    _buildStatTile(
                      icon: Icons.people_alt_rounded,
                      label: 'Users',
                      value: '${data.uniqueUsers}',
                      color: AppTheme.accentTeal,
                      isWide: isWide,
                    ),
                    _buildStatTile(
                      icon: Icons.login_rounded,
                      label: 'Sessions',
                      value: '${data.totalSessions}',
                      color: Colors.blueAccent,
                      isWide: isWide,
                    ),
                    _buildStatTile(
                      icon: Icons.ondemand_video_rounded,
                      label: 'Channel Views',
                      value: '${data.channelViews}',
                      color: Theme.of(context).primaryColor,
                      isWide: isWide,
                    ),
                  ];
                  
                  if (isWide) {
                    return Row(
                      children: tiles.map((t) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: t))).toList(),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: tiles.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: t)).toList(),
                    );
                  }
                }
              ),

              const SizedBox(height: 24),
              
              // 3 STATS TILES (ALL TIME)
              Text('All Time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  final tiles = [
                    _buildStatTile(
                      icon: Icons.people_outline_rounded,
                      label: 'Total Users',
                      value: '${data.allTimeUniqueUsers}',
                      color: AppTheme.accentTeal.withValues(alpha: 0.6),
                      isWide: isWide,
                    ),
                    _buildStatTile(
                      icon: Icons.history_rounded,
                      label: 'Total Sessions',
                      value: '${data.allTimeTotalSessions}',
                      color: Colors.blueAccent.withValues(alpha: 0.6),
                      isWide: isWide,
                    ),
                    _buildStatTile(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Total Views',
                      value: '${data.allTimeChannelViews}',
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                      isWide: isWide,
                    ),
                  ];
                  
                  if (isWide) {
                    return Row(
                      children: tiles.map((t) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: t))).toList(),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: tiles.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: t)).toList(),
                    );
                  }
                }
              ),
              
              const SizedBox(height: 28),
              
              // 4-HOUR STATISTICS CHART
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Users by 4-Hour Period (Today)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 220,
                      child: _buildBarChart(data.usersBy4Hour, context),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),
              
              // MOST WATCHED CHANNELS
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Most Watched Channels', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    if (data.topChannels.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No channel viewing data yet for today.', 
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5))
                        ),
                      )
                    else
                      Column(
                        children: data.topChannels.map((ch) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.tv_rounded, color: Colors.grey, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(ch['name'] as String, 
                                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('${ch['total']} views', 
                                    style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12)
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildStatTile({required IconData icon, required String label, required String value, required Color color, required bool isWide}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> buckets, BuildContext context) {
    if (buckets.values.every((v) => v == 0)) {
      return Center(
        child: Text('No active users recorded today yet', 
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5))
        ),
      );
    }
    
    final keys = buckets.keys.toList();
    final maxVal = buckets.values.reduce((a, b) => a > b ? a : b).toDouble();
    
    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < 0 || value.toInt() >= keys.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(keys[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString(), 
                  style: const TextStyle(color: Colors.grey, fontSize: 10)
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        maxY: maxVal * 1.2,
        barGroups: List.generate(keys.length, (i) {
          final val = buckets[keys[i]]!.toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: val,
                color: Theme.of(context).primaryColor,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }
}
