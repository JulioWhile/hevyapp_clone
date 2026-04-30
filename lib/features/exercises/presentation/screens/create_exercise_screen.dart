import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hevy_app/app/theme/colors.dart';
import 'package:hevy_app/core/constants/enums.dart';
import 'package:hevy_app/features/exercises/presentation/providers/exercise_providers.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  MuscleGroup _selectedMuscleGroup = MuscleGroup.chest;
  Equipment _selectedEquipment = Equipment.dumbbell;
  ExerciseType _selectedExerciseType = ExerciseType.compound;

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveExercise() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await ref.read(exerciseDaoProvider).createCustomExercise(
            name: _nameController.text.trim(),
            primaryMuscleGroup: _selectedMuscleGroup.name,
            equipment: _selectedEquipment.name,
            exerciseType: _selectedExerciseType.name,
          );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Custom Exercise'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveExercise,
            child: _isSaving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ─── Name Input ────────────────────────────────
            TextFormField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g., Decline Bench Press',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // ─── Muscle Group ──────────────────────────────
            const Text(
              'Primary Muscle Group',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MuscleGroup>(
              initialValue: _selectedMuscleGroup,
              items: MuscleGroup.values.map((mg) {
                return DropdownMenuItem(
                  value: mg,
                  child: Text(mg.displayName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedMuscleGroup = val);
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Equipment ─────────────────────────────────
            const Text(
              'Equipment',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Equipment>(
              initialValue: _selectedEquipment,
              items: Equipment.values.map((eq) {
                return DropdownMenuItem(
                  value: eq,
                  child: Text(eq.displayName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedEquipment = val);
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Exercise Type ─────────────────────────────
            const Text(
              'Exercise Type',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExerciseType>(
              initialValue: _selectedExerciseType,
              items: ExerciseType.values.map((et) {
                return DropdownMenuItem(
                  value: et,
                  child: Text(et.displayName),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedExerciseType = val);
              },
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
