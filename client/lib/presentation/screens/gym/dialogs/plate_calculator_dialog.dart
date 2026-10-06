import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

class PlateDenomination {
  final double weight;
  final Color color;
  final Color textColor;
  final double height; // Relative display height for visual stack
  final double width;

  const PlateDenomination({
    required this.weight,
    required this.color,
    required this.textColor,
    required this.height,
    required this.width,
  });
}

class PlateAllocation {
  final PlateDenomination plate;
  final int countPerSide;

  const PlateAllocation({
    required this.plate,
    required this.countPerSide,
  });

  int get totalCount => countPerSide * 2;
  double get totalWeight => plate.weight * totalCount;
}

/// Interactive Barbell Plate Calculator with visual sleeve stack rendering,
/// kg/lbs unit toggling, barbell customization, and competition collars support.
class PlateCalculatorDialog extends StatefulWidget {
  final double? initialTargetWeight;

  const PlateCalculatorDialog({super.key, this.initialTargetWeight});

  static Future<double?> show(BuildContext context, {double? initialWeight}) {
    return showDialog<double>(
      context: context,
      builder: (ctx) => PlateCalculatorDialog(initialTargetWeight: initialWeight),
    );
  }

  @override
  State<PlateCalculatorDialog> createState() => _PlateCalculatorDialogState();
}

class _PlateCalculatorDialogState extends State<PlateCalculatorDialog> {
  late TextEditingController _weightController;
  bool _isMetric = true; // true = kg, false = lbs
  bool _useCollars = false; // Competition collars: 2 x 2.5kg = 5.0kg OR 2 x 5lbs = 10lbs
  double _targetWeight = 100.0;
  double _barbellWeight = 20.0; // In current unit

  // Metric denominations (kg)
  static const List<PlateDenomination> _metricDenominations = [
    PlateDenomination(
      weight: 25.0,
      color: Color(0xFFD32F2F), // Red
      textColor: Colors.white,
      height: 110.0,
      width: 22.0,
    ),
    PlateDenomination(
      weight: 20.0,
      color: Color(0xFF1976D2), // Blue
      textColor: Colors.white,
      height: 104.0,
      width: 20.0,
    ),
    PlateDenomination(
      weight: 15.0,
      color: Color(0xFFFBC02D), // Yellow
      textColor: Colors.black,
      height: 94.0,
      width: 18.0,
    ),
    PlateDenomination(
      weight: 10.0,
      color: Color(0xFF388E3C), // Green
      textColor: Colors.white,
      height: 84.0,
      width: 17.0,
    ),
    PlateDenomination(
      weight: 5.0,
      color: Color(0xFFECEFF1), // White
      textColor: Color(0xFF263238),
      height: 68.0,
      width: 15.0,
    ),
    PlateDenomination(
      weight: 2.5,
      color: Color(0xFF212121), // Black
      textColor: Colors.white,
      height: 54.0,
      width: 13.0,
    ),
    PlateDenomination(
      weight: 1.25,
      color: Color(0xFF78909C), // Chrome / Silver micro
      textColor: Colors.white,
      height: 44.0,
      width: 11.0,
    ),
  ];

  // Imperial denominations (lbs)
  static const List<PlateDenomination> _imperialDenominations = [
    PlateDenomination(
      weight: 45.0,
      color: Color(0xFF1976D2), // Blue 45s
      textColor: Colors.white,
      height: 110.0,
      width: 22.0,
    ),
    PlateDenomination(
      weight: 35.0,
      color: Color(0xFFFBC02D), // Yellow 35s
      textColor: Colors.black,
      height: 98.0,
      width: 19.0,
    ),
    PlateDenomination(
      weight: 25.0,
      color: Color(0xFF388E3C), // Green 25s
      textColor: Colors.white,
      height: 88.0,
      width: 17.0,
    ),
    PlateDenomination(
      weight: 10.0,
      color: Color(0xFF212121), // Black 10s
      textColor: Colors.white,
      height: 72.0,
      width: 14.0,
    ),
    PlateDenomination(
      weight: 5.0,
      color: Color(0xFFECEFF1), // White 5s
      textColor: Color(0xFF263238),
      height: 58.0,
      width: 12.0,
    ),
    PlateDenomination(
      weight: 2.5,
      color: Color(0xFF78909C), // Chrome micro
      textColor: Colors.white,
      height: 46.0,
      width: 11.0,
    ),
  ];

  List<PlateDenomination> get _activeDenominations =>
      _isMetric ? _metricDenominations : _imperialDenominations;

  double get _collarsTotalWeight {
    if (!_useCollars) return 0.0;
    return _isMetric ? 5.0 : 10.0; // 2 x 2.5kg OR 2 x 5lbs
  }

  @override
  void initState() {
    super.initState();
    _targetWeight = widget.initialTargetWeight ?? 100.0;
    if (_targetWeight < 20.0) _targetWeight = 20.0;
    _barbellWeight = 20.0;
    _weightController = TextEditingController(
      text: _targetWeight == _targetWeight.roundToDouble()
          ? _targetWeight.toInt().toString()
          : _targetWeight.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _onUnitChanged(bool metric) {
    if (_isMetric == metric) return;
    setState(() {
      _isMetric = metric;
      if (_isMetric) {
        // Converted from lbs to kg
        _targetWeight = (_targetWeight / 2.20462 * 2).round() / 2; // round to 0.5kg
        _barbellWeight = 20.0;
      } else {
        // Converted from kg to lbs
        _targetWeight = (_targetWeight * 2.20462 / 5).round() * 5; // round to 5lbs
        _barbellWeight = 45.0;
      }
      _weightController.text = _targetWeight == _targetWeight.roundToDouble()
          ? _targetWeight.toInt().toString()
          : _targetWeight.toStringAsFixed(1);
    });
  }

  void _updateWeight(double newWeight) {
    if (newWeight < 0) newWeight = 0;
    setState(() {
      _targetWeight = (newWeight * 10).round() / 10;
      _weightController.text = _targetWeight == _targetWeight.roundToDouble()
          ? _targetWeight.toInt().toString()
          : _targetWeight.toStringAsFixed(1);
    });
  }

  /// Greedily computes the optimal plate configuration required per sleeve
  List<PlateAllocation> _computeAllocations() {
    final double netWeight = _targetWeight - _barbellWeight - _collarsTotalWeight;
    if (netWeight <= 0) return [];

    double singleSleeveWeight = netWeight / 2.0;
    final List<PlateAllocation> allocations = [];

    for (final denom in _activeDenominations) {
      if (singleSleeveWeight >= denom.weight) {
        final count = (singleSleeveWeight / denom.weight).floor();
        if (count > 0) {
          allocations.add(PlateAllocation(plate: denom, countPerSide: count));
          singleSleeveWeight -= count * denom.weight;
          singleSleeveWeight = (singleSleeveWeight * 100).round() / 100;
        }
      }
    }

    return allocations;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allocations = _computeAllocations();
    final unitStr = _isMetric ? 'kg' : 'lbs';

    final double loadedSleeveWeight = allocations.fold(
      0.0,
      (acc, a) => acc + (a.plate.weight * a.countPerSide),
    );
    final double totalCalculatedWeight =
        _barbellWeight + _collarsTotalWeight + (loadedSleeveWeight * 2);
    final double unmatchedRemainder = _targetWeight - totalCalculatedWeight;

    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center_rounded, color: colorScheme.primary, size: 22),
              const SizedBox(width: AppSpacing.xs),
              const Text('Plate Calculator'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Unit & Collars Toolbar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('KG')),
                      ButtonSegment(value: false, label: Text('LBS')),
                    ],
                    selected: {_isMetric},
                    onSelectionChanged: (val) => _onUnitChanged(val.first),
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  FilterChip(
                    avatar: Icon(
                      Icons.lock_outline_rounded,
                      size: 14,
                      color: _useCollars ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      _isMetric ? 'Collars (+5kg)' : 'Collars (+10lbs)',
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _useCollars,
                    onSelected: (val) => setState(() => _useCollars = val),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Target Weight Input & Steppers
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(120),
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          onPressed: () => _updateWeight(_targetWeight - (_isMetric ? 2.5 : 5.0)),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Target Load',
                              suffixText: unitStr,
                              suffixStyle: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              border: const OutlineInputBorder(borderSide: BorderSide.none),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                            onChanged: (val) {
                              final parsed = double.tryParse(val.trim());
                              if (parsed != null && parsed >= 0) {
                                setState(() => _targetWeight = parsed);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton.filledTonal(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          onPressed: () => _updateWeight(_targetWeight + (_isMetric ? 2.5 : 5.0)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Quick Increment Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _isMetric
                            ? [
                                _quickChip(60),
                                _quickChip(80),
                                _quickChip(100),
                                _quickChip(120),
                                _quickChip(140),
                                _quickChip(160),
                              ]
                            : [
                                _quickChip(135),
                                _quickChip(185),
                                _quickChip(225),
                                _quickChip(275),
                                _quickChip(315),
                                _quickChip(365),
                              ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Barbell Baseline Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Barbell Baseline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SegmentedButton<double>(
                    segments: _isMetric
                        ? const [
                            ButtonSegment(value: 20.0, label: Text('20kg')),
                            ButtonSegment(value: 15.0, label: Text('15kg')),
                            ButtonSegment(value: 10.0, label: Text('10kg')),
                            ButtonSegment(value: 0.0, label: Text('0kg')),
                          ]
                        : const [
                            ButtonSegment(value: 45.0, label: Text('45lb')),
                            ButtonSegment(value: 35.0, label: Text('35lb')),
                            ButtonSegment(value: 25.0, label: Text('25lb')),
                            ButtonSegment(value: 0.0, label: Text('0lb')),
                          ],
                    selected: {_barbellWeight},
                    onSelectionChanged: (val) {
                      setState(() => _barbellWeight = val.first);
                    },
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Visual Barbell Sleeve Representation
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Horizontal Barbell Sleeve Axis
                    Positioned(
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 14,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey.shade700,
                              Colors.grey.shade400,
                              Colors.grey.shade600,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),

                    // Left Collar Stop
                    Positioned(
                      left: 28,
                      child: Container(
                        width: 14,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey.shade600),
                        ),
                      ),
                    ),

                    // Loaded Plate Stack (from Collar Outward)
                    Positioned(
                      left: 44,
                      child: allocations.isEmpty
                          ? Text(
                              _targetWeight <= _barbellWeight
                                  ? 'Empty Bar (Bar only: $_barbellWeight$unitStr)'
                                  : 'No plates required',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final item in allocations)
                                  for (int i = 0; i < item.countPerSide; i++)
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                      width: item.plate.width,
                                      height: item.plate.height,
                                      decoration: BoxDecoration(
                                        color: item.plate.color,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(
                                          color: Colors.black.withAlpha(70),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(60),
                                            blurRadius: 3,
                                            offset: const Offset(1, 1),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            item.plate.weight == item.plate.weight.roundToDouble()
                                                ? '${item.plate.weight.toInt()}'
                                                : '${item.plate.weight}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: item.plate.textColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                if (_useCollars)
                                  Container(
                                    margin: const EdgeInsets.only(left: 3),
                                    width: 12,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade700,
                                      borderRadius: BorderRadius.circular(2),
                                      border: Border.all(color: Colors.amber.shade900),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.lock, size: 8, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Summary Breakdown Matrix
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Per Sleeve: ${loadedSleeveWeight.toStringAsFixed(1)} $unitStr',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Total: ${totalCalculatedWeight.toStringAsFixed(1)} $unitStr',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              if (_useCollars) ...[
                const SizedBox(height: 2),
                Text(
                  'Includes collar pair: ${_collarsTotalWeight.toStringAsFixed(1)} $unitStr total (${(_collarsTotalWeight / 2).toStringAsFixed(1)}$unitStr/side)',
                  style: TextStyle(fontSize: 11, color: colorScheme.primary),
                ),
              ],
              if (unmatchedRemainder.abs() > 0.01) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '⚠️ ${unmatchedRemainder.abs().toStringAsFixed(2)}$unitStr remainder cannot be loaded with standard plates',
                  style: TextStyle(fontSize: 11, color: colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),

              // Plate Denomination Pill Catalog
              if (allocations.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: allocations.map((a) {
                    final label = a.plate.weight == a.plate.weight.roundToDouble()
                        ? '${a.plate.weight.toInt()} $unitStr'
                        : '${a.plate.weight} $unitStr';
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: a.plate.color,
                        radius: 8,
                      ),
                      label: Text(
                        '$label × ${a.countPerSide} (side) / × ${a.totalCount} (total)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillRadius),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () {
            // If in lbs, convert back to kg for standard internal storage
            final double resultKg = _isMetric ? _targetWeight : _targetWeight / 2.20462;
            Navigator.pop(context, (resultKg * 10).round() / 10);
          },
          child: const Text('Use Load'),
        ),
      ],
    );
  }

  Widget _quickChip(double weight) {
    final isSelected = _targetWeight == weight;
    final unitStr = _isMetric ? 'kg' : 'lbs';
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text('${weight.toInt()}$unitStr'),
        selected: isSelected,
        visualDensity: VisualDensity.compact,
        labelStyle: const TextStyle(fontSize: 11),
        onSelected: (_) => _updateWeight(weight),
      ),
    );
  }
}
