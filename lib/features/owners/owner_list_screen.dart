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
import 'package:go_router/go_router.dart';
import 'package:spring_petclinic_flutter/shared/navigation/app_routes.dart';

import '../../shared/theme/classic_theme.dart';
import '../../shared/widgets/classic_scaffold.dart';
import 'owner.dart';
import 'owner_service.dart';

class OwnerListScreen extends StatefulWidget {
  const OwnerListScreen({super.key, this.ownerService});

  final OwnerService? ownerService;

  @override
  State<OwnerListScreen> createState() => _OwnerListScreenState();
}

class _OwnerListScreenState extends State<OwnerListScreen> {
  static const int _ownersPageSize = 5;

  late final OwnerService _ownerService = widget.ownerService ?? OwnerService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  String _activeQuery = '';
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  List<Owner> _owners = const [];

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasPages => _totalElements > 0 && _totalPages > 0;

  bool get _canGoPrevious => _currentPage > 0;

  bool get _canGoNext => _hasPages && _currentPage < _totalPages - 1;

  String get _pageLabel {
    final displayPage = _hasPages ? _currentPage + 1 : 0;
    return 'Page $displayPage of $_totalPages';
  }

  Future<void> _loadOwners({String? lastName, int? page}) async {
    final requestedQuery = lastName?.trim() ?? _activeQuery;
    final requestedPage = page ?? _currentPage;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _activeQuery = requestedQuery;
      _currentPage = requestedPage;
    });

    try {
      final ownersPage = await _ownerService.listOwnersPage(
        lastName: requestedQuery.isEmpty ? null : requestedQuery,
        page: requestedPage,
        size: _ownersPageSize,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _owners = ownersPage.content;
        _currentPage = ownersPage.page;
        _totalPages = ownersPage.totalPages;
        _totalElements = ownersPage.totalElements;
      });
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

  Future<void> _openOwnerForm() async {
    final changed = await context.push<bool>(AppRoutes.ownerNew);
    if (changed == true) {
      await _loadOwners();
    }
  }

  Future<void> _openOwnerDetail(Owner owner) async {
    final changed = await context.push<bool>(AppRoutes.owner(owner.id!));
    if (changed == true) {
      await _loadOwners();
    }
  }

  Future<void> _goToPreviousPage() async {
    if (!_canGoPrevious) {
      return;
    }
    await _loadOwners(page: _currentPage - 1);
  }

  Future<void> _goToNextPage() async {
    if (!_canGoNext) {
      return;
    }
    await _loadOwners(page: _currentPage + 1);
  }

  @override
  Widget build(BuildContext context) {
    return ClassicScaffold(
      section: ClassicSection.owners,
      title: 'Owners',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 180;

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, compact ? 8 : 16),
                child: _SearchOwnersForm(
                  controller: _searchController,
                  compact: compact,
                  onSearch: () {
                    _loadOwners(
                      lastName: _searchController.text.trim(),
                      page: 0,
                    );
                  },
                ),
              ),
              Expanded(child: _buildContent()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: FilledButton(
              onPressed: () => _loadOwners(),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }

    if (_owners.isEmpty) {
      final message = _activeQuery.isEmpty
          ? 'No owners found.'
          : 'No owners with last name starting with "$_activeQuery".';
      final supportingMessage = _activeQuery.isEmpty
          ? 'Add an owner to get started.'
          : 'Try a different last name or add a new owner.';
      return RefreshIndicator(
        onRefresh: () => _loadOwners(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _OwnersEmptyState(
              message: message,
              supportingMessage: supportingMessage,
              onAddOwner: _openOwnerForm,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOwners(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tableWidth = constraints.maxWidth < 760
                  ? 760.0
                  : constraints.maxWidth;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: _OwnersTable(
                    owners: _owners,
                    onOpenOwner: _openOwnerDetail,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _canGoPrevious ? _goToPreviousPage : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 16),
              Text(_pageLabel),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: _canGoNext ? _goToNextPage : null,
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _openOwnerForm,
              child: const Text('Add Owner'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnersEmptyState extends StatelessWidget {
  const _OwnersEmptyState({
    required this.message,
    required this.supportingMessage,
    required this.onAddOwner,
  });

  final String message;
  final String supportingMessage;
  final VoidCallback onAddOwner;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicPalette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.person_search_outlined,
              size: 42,
              color: ClassicPalette.accent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(supportingMessage, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onAddOwner, child: const Text('Add Owner')),
          ],
        ),
      ),
    );
  }
}

class _SearchOwnersForm extends StatelessWidget {
  const _SearchOwnersForm({
    required this.controller,
    required this.onSearch,
    this.compact = false,
  });

  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 680;

        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(labelText: 'Last name'),
                onSubmitted: (_) => onSearch(),
              ),
              SizedBox(height: compact ? 8 : 12),
              OutlinedButton(
                onPressed: onSearch,
                child: const Text('Find Owner'),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    'Last name',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(),
                    onSubmitted: (_) => onSearch(),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 8 : 12),
            Padding(
              padding: const EdgeInsets.only(left: 130),
              child: OutlinedButton(
                onPressed: onSearch,
                child: const Text('Find Owner'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OwnersTable extends StatelessWidget {
  const _OwnersTable({required this.owners, required this.onOpenOwner});

  final List<Owner> owners;
  final ValueChanged<Owner> onOpenOwner;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: ClassicPalette.border),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.2),
          1: FlexColumnWidth(2.6),
          2: FlexColumnWidth(1.5),
          3: FlexColumnWidth(1.7),
          4: FlexColumnWidth(1.2),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: const BoxDecoration(color: ClassicPalette.tableHeader),
            children: const [
              _HeaderCell('Name'),
              _HeaderCell('Address'),
              _HeaderCell('City'),
              _HeaderCell('Telephone'),
              _HeaderCell('Pets'),
            ],
          ),
          for (var index = 0; index < owners.length; index++)
            TableRow(
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : const Color(0xFFF8F8F8),
                border: const Border(
                  bottom: BorderSide(color: ClassicPalette.border),
                ),
              ),
              children: [
                _LinkCell(
                  label: owners[index].fullName,
                  onTap: () => onOpenOwner(owners[index]),
                ),
                _DataCellText(owners[index].address),
                _DataCellText(owners[index].city),
                _DataCellText(owners[index].telephone),
                _PetsCell(
                  pets: owners[index].pets.map((pet) => pet.name).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _DataCellText extends StatelessWidget {
  const _DataCellText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(value),
    );
  }
}

class _LinkCell extends StatelessWidget {
  const _LinkCell({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: onTap,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: ClassicPalette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _PetsCell extends StatelessWidget {
  const _PetsCell({required this.pets});

  final List<String> pets;

  @override
  Widget build(BuildContext context) {
    final entries = pets.isEmpty ? const [''] : pets;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final pet in entries) Text(pet)],
      ),
    );
  }
}
