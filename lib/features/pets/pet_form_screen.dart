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
import '../../shared/utils/date_utils.dart';
import '../../shared/widgets/page_width.dart';
import '../owners/owner.dart';
import '../owners/owner_service.dart';
import '../pettypes/pet_type.dart';
import '../pettypes/pet_type_service.dart';
import 'pet.dart';
import 'pet_service.dart';

class PetFormScreen extends StatefulWidget {
  const PetFormScreen({super.key, this.ownerId, this.petId})
    : assert(ownerId != null || petId != null);

  final int? ownerId;
  final int? petId;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final OwnerService _ownerService = OwnerService();
  final PetService _petService = PetService();
  final PetTypeService _petTypeService = PetTypeService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  Owner? _owner;
  Pet? _pet;
  List<PetType> _petTypes = const [];
  PetType? _selectedType;
  DateTime? _selectedBirthDate;

  bool get _isEditing => widget.petId != null;
  String get _fallbackRoute {
    final ownerId = _owner?.id ?? widget.ownerId;
    return ownerId == null ? AppRoutes.owners : AppRoutes.owner(ownerId);
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isEditing) {
        final results = await Future.wait<dynamic>([
          _petService.getPet(widget.petId!),
          _petTypeService.listPetTypes(),
        ]);
        final pet = results[0] as Pet;
        final petTypes = results[1] as List<PetType>;
        final owner = await _ownerService.getOwner(pet.ownerId!);

        if (!mounted) {
          return;
        }

        setState(() {
          _pet = pet;
          _owner = owner;
          _petTypes = petTypes;
          _selectedType = petTypes.firstWhere(
            (type) => type.id == pet.type.id,
            orElse: () => pet.type,
          );
          _selectedBirthDate = parseApiDate(pet.birthDate);
          _nameController.text = pet.name;
          _birthDateController.text = pet.birthDate;
        });
      } else {
        final results = await Future.wait<dynamic>([
          _ownerService.getOwner(widget.ownerId!),
          _petTypeService.listPetTypes(),
        ]);
        if (!mounted) {
          return;
        }
        setState(() {
          _owner = results[0] as Owner;
          _petTypes = results[1] as List<PetType>;
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month, now.day);
    final firstDate = AppValidators.minimumPetBirthDate(lastDate);
    final initialDate = _birthDatePickerInitialDate(
      firstDate: firstDate,
      lastDate: lastDate,
    );
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedBirthDate = selected;
      _birthDateController.text = formatApiDate(selected);
    });
  }

  DateTime _birthDatePickerInitialDate({
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final selectedBirthDate = _selectedBirthDate;
    if (selectedBirthDate == null) {
      return lastDate;
    }

    final selectedDate = DateTime(
      selectedBirthDate.year,
      selectedBirthDate.month,
      selectedBirthDate.day,
    );
    if (selectedDate.isBefore(firstDate)) {
      return firstDate;
    }
    if (selectedDate.isAfter(lastDate)) {
      return lastDate;
    }
    return selectedDate;
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

    final pet = Pet(
      id: _pet?.id,
      ownerId: _owner?.id,
      name: _nameController.text.trim(),
      birthDate: _birthDateController.text.trim(),
      type: _selectedType!,
      visits: _pet?.visits ?? const [],
    );

    try {
      if (_isEditing) {
        await _petService.updatePet(pet);
      } else {
        await _petService.createPet(_owner!.id!, pet);
      }

      if (!mounted) {
        return;
      }
      context.popOrGo<bool>(_fallbackRoute, result: true);
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
    final petTypeItems = [
      ..._petTypes,
      if (_selectedType != null &&
          !_petTypes.any((type) => type.id == _selectedType!.id))
        _selectedType!,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Pet' : 'Add Pet')),
      body: AppPageWidth(
        maxWidth: 720,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && _owner == null
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(_owner?.fullName ?? ''),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: AppValidators.plainText(
                            'Name',
                            minLength: 1,
                            maxLength: 30,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Birth Date',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          onTap: _pickBirthDate,
                          validator: AppValidators.petBirthDate('Birth date'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PetType>(
                          initialValue: _selectedType,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: petTypeItems
                              .map(
                                (petType) => DropdownMenuItem<PetType>(
                                  value: petType,
                                  child: Text(petType.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Pet type is required.';
                            }
                            return null;
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
                            label: Text(_isEditing ? 'Update Pet' : 'Save Pet'),
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
