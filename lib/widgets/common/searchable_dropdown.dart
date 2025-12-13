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
  final TextEditingController _searchController = TextEditingController();
  bool _isOpen = false;
  List<LookupOption> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchableDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _filteredOptions = widget.options;
      _searchController.clear();
    }
    if (!widget.enabled && _isOpen) {
      setState(() {
        _isOpen = false;
        _searchController.clear();
        _filteredOptions = widget.options;
      });
    }
  }

  void _filterOptions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options
            .where((option) =>
                option.label.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectOption(LookupOption option) {
    widget.onChanged(option.value?.toString());
    Navigator.of(context).pop();
    setState(() {
      _isOpen = false;
      _searchController.clear();
      _filteredOptions = widget.options;
    });
  }

  void _showModal() {
    if (!widget.enabled) return;

    setState(() {
      _isOpen = true;
      _filteredOptions = widget.options;
      _searchController.clear();
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildModalContent(),
    ).then((_) {
      setState(() {
        _isOpen = false;
        _searchController.clear();
        _filteredOptions = widget.options;
      });
    });
  }

  Widget _buildModalContent() {
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
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: _filterOptions,
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
                      final option = _filteredOptions[index];
                      return RadioListTile<String?>(
                        title: Text(option.label),
                        value: option.value?.toString(),
                        groupValue: widget.value,
                        onChanged: (value) => _selectOption(option),
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

