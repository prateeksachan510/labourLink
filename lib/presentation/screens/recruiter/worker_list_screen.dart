import 'package:flutter/material.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/core/widgets/app_card.dart';
import 'package:labour_link/core/widgets/empty_state_view.dart';
import 'package:labour_link/core/widgets/loading_view.dart';
import 'package:labour_link/core/widgets/user_avatar.dart';
import 'package:labour_link/core/widgets/verified_badge.dart';
import 'package:labour_link/presentation/providers/recruiter_provider.dart';
import 'package:labour_link/presentation/screens/recruiter/worker_detail_screen.dart';
import 'package:provider/provider.dart';

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key, required this.profession});
  final String profession;

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecruiterProvider>().loadWorkers(widget.profession);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recruiter = context.watch<RecruiterProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.onBackground,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.profession,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.onBackground,
                            ),
                          ),
                          Text(
                            '${recruiter.workers.length} workers found',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.subtle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: AppTheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by name or location...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.subtle,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => context
                          .read<RecruiterProvider>()
                          .loadWorkers(
                            widget.profession,
                            query: _search.text,
                          ),
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  onSubmitted: (v) => context
                      .read<RecruiterProvider>()
                      .loadWorkers(widget.profession, query: v),
                ),
              ),
              Expanded(
                child: recruiter.isLoading
                    ? const LoadingView()
                    : recruiter.workers.isEmpty
                        ? const EmptyStateView(message: 'No workers found')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: recruiter.workers.length,
                            itemBuilder: (context, index) {
                              final worker = recruiter.workers[index];
                              return AppCard(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        WorkerDetailScreen(worker: worker),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    UserAvatar(user: worker, radius: 26),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            worker.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppTheme.onBackground,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (worker.isVerified)
                                            const VerifiedBadge(compact: true),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 13,
                                                color: AppTheme.subtle,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                worker.location,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme.subtle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'View',
                                        style: TextStyle(
                                          color: AppTheme.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
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
      ),
    );
  }
}
