import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/app_error_state.dart';
import '../../widgets/app_empty_state.dart';

class CourseItemModel {
  final String id;
  final String name;
  final String? code;
  final String? instructor;
  final String? room;

  CourseItemModel({
    required this.id,
    required this.name,
    this.code,
    this.instructor,
    this.room,
  });

  factory CourseItemModel.fromJson(Map<String, dynamic> json) {
    return CourseItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      instructor: json['instructor'],
      room: json['room'],
    );
  }
}

final academicCoursesProvider =
    FutureProvider.autoDispose<List<CourseItemModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get(ApiEndpoints.courses);
  final data = response.data['data'];
  List items = [];
  if (data is Map && data.containsKey('data')) {
    items = data['data'] as List;
  } else if (data is List) {
    items = data;
  }
  return items
      .map((i) => CourseItemModel.fromJson(Map<String, dynamic>.from(i)))
      .toList();
});

class AcademicScreen extends ConsumerWidget {
  const AcademicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(academicCoursesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic & Courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(academicCoursesProvider),
          ),
        ],
      ),
      body: coursesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(academicCoursesProvider),
        ),
        data: (courses) {
          if (courses.isEmpty) {
            return AppEmptyState(
              icon: Icons.school_outlined,
              title: 'No academic courses enrolled',
              description: 'Tap "+ Add Course" to track assignments & exams.',
              actionLabel: 'Add Course',
              onAction: () => _openCreateCourseDialog(context, ref),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(academicCoursesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final c = courses[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: colorScheme.surfaceContainerHighest,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.class_outlined,
                          color: colorScheme.primary, size: 20),
                    ),
                    title: Text(
                      c.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: Text(
                      '${c.code != null ? '${c.code} • ' : ''}${c.instructor ?? 'No Instructor'}',
                    ),
                    trailing: c.room != null
                        ? Chip(
                            label: Text(c.room!),
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateCourseDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Course'),
      ),
    );
  }

  Future<void> _openCreateCourseDialog(
      BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final instructorController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Course'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Course Name *',
                  hintText: 'e.g. Operating Systems',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Course Code (optional)',
                  hintText: 'e.g. CS401',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructorController,
                decoration: const InputDecoration(
                  labelText: 'Instructor (optional)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      final dio = ref.read(dioProvider);
      await dio.post(ApiEndpoints.courses, data: {
        'name': nameController.text.trim(),
        if (codeController.text.trim().isNotEmpty)
          'code': codeController.text.trim(),
        if (instructorController.text.trim().isNotEmpty)
          'instructor': instructorController.text.trim(),
      });
      ref.invalidate(academicCoursesProvider);
    }
  }
}
