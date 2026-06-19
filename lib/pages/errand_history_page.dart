import 'package:flutter/material.dart';

import '../models/errand.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';
import 'errand_view.dart';

class ErrandHistoryPage extends StatelessWidget {
  const ErrandHistoryPage({super.key});

  Future<List<Errand>> _loadPostedErrands() {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      return Future.value(const []);
    }

    return DatabaseService.instance.getUserPostedErrands(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Errand History")),

      body: FutureBuilder<List<Errand>>(
        future: _loadPostedErrands(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final errands = snapshot.data ?? [];

          if (errands.isEmpty) {
            return const Center(child: Text("No errands posted yet"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: errands.length,
            itemBuilder: (context, index) {
              final errand = errands[index];

              final isDone = errand.status == 'Completed';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ErrandView(errandId: errand.id!),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TITLE + STATUS BADGE
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                errand.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF18074d),
                                ),
                              ),
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? const Color(0xFFffc95c)
                                    : const Color(0xFFFF643D),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                errand.displayStatus,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Text(
                          errand.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600]),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // REWARD
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFF643D,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                "Reward",
                                style: TextStyle(
                                  color: Color(0xFFFF643D),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Text(
                              "RM ${errand.reward}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF422a59),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
