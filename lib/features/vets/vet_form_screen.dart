/*
 * Copyright 2002-2017 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';

import '../../shared/forms/app_validators.dart';
import '../../shared/navigation/app_routes.dart';
import '../../shared/navigation/navigation_extensions.dart';
import '../../shared/widgets/page_width.dart';
import '../specialties/specialty.dart';
import '../specialties/specialty_service.dart';
import 'vet.dart';
import 'vet_service.dart';

class VetFormScreen extends StatefulWidget {
  const VetFormScreen({super.key, this.vetId});

  final int? vetId;

  @override
  State<VetFormScreen> createState() => _VetFormScreenState();
}

class _VetFormScreenState extends State<VetFormScreen> {
  final VetService _vetService = VetService();
  final SpecialtyService _specialtyService = SpecialtyService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  Vet? _vet;
  List<Specialty> _specialties = const [];
  Specialty? _selectedSpecialty;
  final Set<int> _selectedSpecialtyIds = <int>{};

  bool get _isEditing => widget.vetId != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final specialties = await _specialtyService.listSpecialties();

      if (_isEditing) {
        final vet = await _vetService.getVet(widget.vetId!);
        if (!mounted) {
          return;
        }
        setState(() {
          _specialties = specialties;
          _vet = vet;
          _firstNameController.text = vet.firstName;
          _lastNameController.text = vet.lastName;
          _selectedSpecialtyIds
            ..clear()
            ..addAll(vet.specialties.map((specialty) => specialty.id!));
        });
      } else {
        if (!mounted) {
          return;
        }
        setState(() {
          _specialties = specialties;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Specialty> _buildSelectedSpecialties() {
    if (_isEditing) {
      return _specialties
          .where((specialty) => _selectedSpecialtyIds.contains(specialty.id))
          .toList();
    }

    if (_selectedSpecialty == null) {
      return const [];
    }

    return <Specialty>[_selectedSpecialty!];
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final vet = Vet(
      id: _vet?.id,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      specialties: _buildSelectedSpecialties(),
    );

    try {
      if (_isEditing) {
        await _vetService.updateVet(vet);
      } else {
        await _vetService.createVet(vet);
      }

      if (!mounted) {
        return;
      }
      context.popOrGo<bool>(AppRoutes.veterinarians, result: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Veterinarian' : 'New Veterinarian'),
      ),
      body: AppPageWidth(
        maxWidth: 720,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _specialties.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_errorMessage!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_errorMessage != null) ...[
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_errorMessage!),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                          ),
                          validator: AppValidators.firstName(
                            'First name',
                            minLength: 1,
                            maxLength: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                          ),
                          validator: AppValidators.lastName(
                            'Last name',
                            minLength: 1,
                            maxLength: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isEditing)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Specialties',
                            ),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _specialties
                                  .map(
                                    (specialty) => FilterChip(
                                      label: Text(specialty.name),
                                      selected: _selectedSpecialtyIds.contains(
                                        specialty.id,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedSpecialtyIds.add(
                                              specialty.id!,
                                            );
                                          } else {
                                            _selectedSpecialtyIds.remove(
                                              specialty.id,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                        else
                          DropdownButtonFormField<Specialty?>(
                            initialValue: _selectedSpecialty,
                            decoration: const InputDecoration(
                              labelText: 'Specialty',
                            ),
                            items: [
                              const DropdownMenuItem<Specialty?>(
                                value: null,
                                child: Text('No specialty'),
                              ),
                              ..._specialties.map(
                                (specialty) => DropdownMenuItem<Specialty?>(
                                  value: specialty,
                                  child: Text(specialty.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedSpecialty = value;
                              });
                            },
                          ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(_isEditing ? 'Save Vet' : 'Add Vet'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
