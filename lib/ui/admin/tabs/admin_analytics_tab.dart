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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        children: [
          // SUMMARY TILES
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StreamBuilder<int>(
                stream: analyticsService.getLiveUsersStream(),
                builder: (context, snap) {
                  return _statTile(
                    icon: Icons.people_alt_rounded,
                    label: 'Live Users',
                    value: '${snap.data ?? 0}',
                    color: AppTheme.accentTeal,
                  );
                },
              ),
              StreamBuilder<int>(
                stream: analyticsService.getTotalViewsStream(),
                builder: (context, snap) {
                  return _statTile(
                    icon: Icons.visibility_rounded,
                    label: 'Total Opens',
                    value: '${snap.data ?? 0}',
                    color: Theme.of(context).primaryColor,
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 28),
          
          // DAILY VIEWS CHART
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('App Opens (Last 7 Days)', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: StreamBuilder<Map<String, int>>(
                    stream: analyticsService.getDailyViewsStream(),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return Center(
                          child: Text('Not enough data to draw chart', 
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5))
                          ),
                        );
                      }
                      
                      final data = snap.data!;
                      // Sort by date key (assuming ISO dates or sortable IDs)
                      final sortedKeys = data.keys.toList()..sort();
                      final recentKeys = sortedKeys.length > 7 
                          ? sortedKeys.sublist(sortedKeys.length - 7) 
                          : sortedKeys;
                          
                      final spots = <FlSpot>[];
                      double maxVal = 10;
                      for (int i = 0; i < recentKeys.length; i++) {
                        final val = data[recentKeys[i]]!.toDouble();
                        spots.add(FlSpot(i.toDouble(), val));
                        if (val > maxVal) maxVal = val;
                      }
                      
                      return LineChart(
                        LineChartData(
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
                            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 1,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < 0 || value.toInt() >= recentKeys.length) {
                                    return const SizedBox.shrink();
                                  }
                                  // Extract "MM-DD" from date string if possible
                                  String label = recentKeys[value.toInt()];
                                  if (label.length >= 10) {
                                    label = label.substring(5, 10);
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
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
                          minX: 0,
                          maxX: (recentKeys.length - 1).toDouble(),
                          minY: 0,
                          maxY: maxVal * 1.2,
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: Theme.of(context).primaryColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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
          ),
          
          const SizedBox(height: 28),
          
          // TOP CHANNELS
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top 10 Channels', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: analyticsService.getTopChannelsStream(limit: 10),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('No channel viewing data yet', 
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5))
                        ),
                      );
                    }
                    
                    return Column(
                      children: snap.data!.map((ch) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.tv_rounded, color: Colors.grey, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(ch['name'] as String, 
                                  style: const TextStyle(color: Colors.white, fontSize: 14)
                                ),
                              ),
                              Text('${ch['total']} views', 
                                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
