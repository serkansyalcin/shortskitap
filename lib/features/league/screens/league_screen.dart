import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/league_provider.dart';
import 'package:kitaplig/core/models/league_model.dart';
import '../widgets/league_header.dart';
import '../widgets/leaderboard_list.dart';
import '../widgets/league_history.dart';

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final leagueAsync = ref.watch(myLeagueProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: leagueAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              const Text('Lig bilgisi yüklenemedi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(myLeagueProvider),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        ),
        data: (status) => _buildContent(status),
      ),
    );
  }

  Widget _buildContent(LeagueStatusModel status) {
    final tierColor = Color(
      int.parse(status.membership.tierColor.replaceFirst('#', 'FF'), radix: 16),
    );

    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          elevation: 0,
          backgroundColor: tierColor,
          flexibleSpace: FlexibleSpaceBar(
            background: LeagueHeader(status: status, tierColor: tierColor),
          ),
          bottom: TabBar(
            controller: _tabs,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            tabs: const [
              Tab(text: 'Liderboard'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabs,
        children: [
          LeaderboardList(membership: status.membership),
          const LeagueHistory(),
        ],
      ),
    );
  }
}
