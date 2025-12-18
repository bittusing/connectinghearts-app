import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../models/profile_models.dart';

class SearchableDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<LookupOption> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String? hint;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.enabled = true,
    this.hint,
  });

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  void _showModal() {
    if (!widget.enabled) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModalContent(),
    );
  }

  Widget _buildModalContent() {
    final initialOptions = widget.options.isNotEmpty
        ? List<LookupOption>.from(widget.options)
        : <LookupOption>[];

    return _SearchableDropdownModal(
      initialOptions: initialOptions,
      currentValue: widget.value,
      label: widget.label,
      onChanged: widget.onChanged,
    );
  }

  String? _getSelectedLabel() {
    if (widget.value == null) return null;
    try {
      final selected = widget.options.firstWhere(
        (opt) => opt.value?.toString() == widget.value,
      );
      return selected.label;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedLabel = _getSelectedLabel();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: widget.enabled ? _showModal : null,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: 48,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? theme.cardColor
                      : theme.cardColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.dividerColor,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel ??
                            widget.hint ??
                            'Select ${widget.label}',
                        style: TextStyle(
                          color: selectedLabel != null
                              ? theme.textTheme.bodyLarge?.color
                              : theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.textTheme.bodySmall?.color,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Separate StatefulWidget for the modal to properly manage state
class _SearchableDropdownModal extends StatefulWidget {
  final List<LookupOption> initialOptions;
  final String? currentValue;
  final String label;
  final ValueChanged<String?> onChanged;

  const _SearchableDropdownModal({
    required this.initialOptions,
    required this.currentValue,
    required this.label,
    required this.onChanged,
  });

  @override
  State<_SearchableDropdownModal> createState() =>
      _SearchableDropdownModalState();
}

class _SearchableDropdownModalState extends State<_SearchableDropdownModal> {
  late TextEditingController _searchController;
  late List<LookupOption> _filteredOptions;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredOptions = List<LookupOption>.from(widget.initialOptions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = List<LookupOption>.from(widget.initialOptions);
      } else {
        _filteredOptions = widget.initialOptions
            .where((option) =>
                option.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Select ${widget.label}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              enableInteractiveSelection: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'Search ${widget.label.toLowerCase()}...',
                hintStyle: TextStyle(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodyLarge?.color ?? Colors.black87,
              ),
              onChanged: _updateFilteredOptions,
            ),
          ),
          const SizedBox(height: 8),
          // Options list
          Flexible(
            child: _filteredOptions.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No matches found',
                      style: theme.textTheme.bodySmall,
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredOptions.length,
                    itemBuilder: (context, index) {
                      if (index >= _filteredOptions.length) {
                        return const SizedBox.shrink();
                      }
                      final option = _filteredOptions[index];
                      return RadioListTile<String?>(
                        title: Text(option.label),
                        value: option.value?.toString(),
                        groupValue: widget.currentValue,
                        onChanged: (value) {
                          widget.onChanged(option.value?.toString());
                          Navigator.of(context).pop();
                        },
                        activeColor: AppColors.primary,
                      );
                    },
                  ),
          ),
          // OK Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
