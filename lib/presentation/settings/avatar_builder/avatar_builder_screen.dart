import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_config.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_preview.dart';
import 'package:spendwise/presentation/settings/avatar_builder/avatar_builder_storage.dart';

class AvatarBuilderScreen extends StatefulWidget {
  const AvatarBuilderScreen({super.key});

  @override
  State<AvatarBuilderScreen> createState() => _AvatarBuilderScreenState();
}

class _AvatarBuilderScreenState extends State<AvatarBuilderScreen> {
  AvatarBuilderConfig initial = const AvatarBuilderConfig();
  AvatarBuilderConfig config = const AvatarBuilderConfig();
  final initials = TextEditingController(text: 'AC');
  bool loading = true, saving = false;

  static const backgrounds = [
    0xFF2563EB,
    0xFF7C3AED,
    0xFF10B981,
    0xFFF97316,
    0xFFDC2626,
  ];
  static const textColors = [
    0xFFFFFFFF,
    0xFF111827,
    0xFF374151,
    0xFFD1D5DB,
    0xFFF5E6D3,
  ];
  static const borderColors = [0xFFFFFFFF, 0xFF111827, 0xFFD1D5DB, 0xFFD99A2B];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final value = await AvatarBuilderStorage.load();
    initial = value;
    config = value;
    initials.text = value.initials;
    if (mounted) setState(() => loading = false);
  }

  void update(AvatarBuilderConfig value) => setState(() => config = value);

  void applyPreset(AvatarBuilderConfig value) {
    final updated = value.copyWith(initials: config.initials);
    initials.text = updated.initials;
    update(updated);
  }

  void randomize() {
    final random = Random();
    final color = backgrounds[random.nextInt(backgrounds.length)];
    final gradient = random.nextBool();
    update(
      config.copyWith(
        backgroundType: gradient ? 'gradient' : 'solid',
        backgroundColor: color,
        gradientStart: color,
        gradientEnd: backgrounds[random.nextInt(backgrounds.length)],
        textColor: textColors[random.nextInt(2)],
        shape: AvatarShape.values[random.nextInt(AvatarShape.values.length)],
        icon: AvatarIcon.values[random.nextInt(AvatarIcon.values.length)],
        borderEnabled: random.nextBool(),
        borderColor: borderColors[random.nextInt(borderColors.length)],
        borderWidth: (2 + random.nextInt(5)).toDouble(),
        size: AvatarSize.values[random.nextInt(AvatarSize.values.length)],
      ),
    );
  }

  void restore() {
    initials.text = initial.initials;
    update(initial);
  }

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await AvatarBuilderStorage.save(config);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    initials.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Personalizza avatar')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (context, constraints) {
              final desktop = constraints.maxWidth >= 880;
              final preview = _PreviewPanel(
                config: config,
                onSize: (value) => update(config.copyWith(size: value)),
                onRandomize: randomize,
                onPreset: applyPreset,
              );
              final controls = _ControlsPanel(
                config: config,
                initials: initials,
                onChanged: update,
              );
              return SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: desktop
                          ? IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(width: 410, child: preview),
                                  VerticalDivider(
                                    width: 1,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                  Expanded(child: controls),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                preview,
                                Divider(
                                  height: 1,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outlineVariant,
                                ),
                                controls,
                              ],
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
    bottomNavigationBar: loading
        ? null
        : SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annulla'),
                  ),
                  OutlinedButton.icon(
                    onPressed: restore,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Ripristina'),
                  ),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Salva modifiche'),
                  ),
                ],
              ),
            ),
          ),
  );
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({
    required this.config,
    required this.onSize,
    required this.onRandomize,
    required this.onPreset,
  });

  final AvatarBuilderConfig config;
  final ValueChanged<AvatarSize> onSize;
  final VoidCallback onRandomize;
  final ValueChanged<AvatarBuilderConfig> onPreset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Anteprima avatar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 28),
        Center(child: AvatarBuilderPreview(config: config)),
        const SizedBox(height: 30),
        Text('Dimensione', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<AvatarSize>(
          segments: const [
            ButtonSegment(value: AvatarSize.small, label: Text('S')),
            ButtonSegment(value: AvatarSize.medium, label: Text('M')),
            ButtonSegment(value: AvatarSize.large, label: Text('L')),
            ButtonSegment(value: AvatarSize.extraLarge, label: Text('XL')),
          ],
          selected: {config.size},
          onSelectionChanged: (value) => onSize(value.first),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onRandomize,
          icon: const Icon(Icons.shuffle),
          label: const Text('Randomizza avatar'),
        ),
        const SizedBox(height: 26),
        Text('Preset rapidi', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: [
            for (final preset in avatarBuilderPresets.values)
              _PresetButton(
                label: preset.$1,
                config: preset.$2.copyWith(initials: config.initials),
                onTap: () => onPreset(preset.$2),
              ),
          ],
        ),
      ],
    ),
  );
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.config,
    required this.initials,
    required this.onChanged,
  });

  final AvatarBuilderConfig config;
  final TextEditingController initials;
  final ValueChanged<AvatarBuilderConfig> onChanged;

  Future<void> customColor(
    BuildContext context,
    int initial,
    ValueChanged<int> onSelected,
  ) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _ColorPickerDialog(initial: initial),
    );
    if (value != null) onSelected(value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Personalizza avatar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 24),
        _ControlGroup(
          title: 'Forma avatar',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final shape in AvatarShape.values)
                _ShapeButton(
                  shape: shape,
                  selected: config.shape == shape,
                  onTap: () => onChanged(config.copyWith(shape: shape)),
                ),
            ],
          ),
        ),
        _ControlGroup(
          title: 'Sfondo',
          child: _ColorPalette(
            selected: config.backgroundType == 'solid'
                ? config.backgroundColor
                : null,
            colors: _AvatarBuilderScreenState.backgrounds,
            gradientSelected: config.backgroundType == 'gradient',
            onColor: (value) => onChanged(
              config.copyWith(backgroundType: 'solid', backgroundColor: value),
            ),
            onGradient: () =>
                onChanged(config.copyWith(backgroundType: 'gradient')),
            onCustom: () => customColor(
              context,
              config.backgroundColor,
              (value) => onChanged(
                config.copyWith(
                  backgroundType: 'solid',
                  backgroundColor: value,
                ),
              ),
            ),
          ),
        ),
        _ControlGroup(
          title: 'Iniziali',
          child: TextField(
            controller: initials,
            maxLength: 3,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'AC',
              prefixIcon: Icon(Icons.text_fields),
              counterText: '',
            ),
            onChanged: (value) => onChanged(config.copyWith(initials: value)),
          ),
        ),
        _ControlGroup(
          title: 'Colore testo',
          child: _ColorPalette(
            selected: config.textColor,
            colors: _AvatarBuilderScreenState.textColors,
            onColor: (value) => onChanged(config.copyWith(textColor: value)),
            onCustom: () => customColor(
              context,
              config.textColor,
              (value) => onChanged(config.copyWith(textColor: value)),
            ),
          ),
        ),
        _ControlGroup(
          title: 'Icona opzionale',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final icon in AvatarIcon.values)
                IconButton.filledTonal(
                  tooltip: icon.name,
                  isSelected: config.icon == icon,
                  onPressed: () => onChanged(config.copyWith(icon: icon)),
                  icon: Icon(
                    icon == AvatarIcon.none
                        ? Icons.text_fields
                        : AvatarBuilderPreview.iconData(icon),
                  ),
                ),
            ],
          ),
        ),
        _ControlGroup(
          title: 'Bordo',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mostra bordo'),
                value: config.borderEnabled,
                onChanged: (value) =>
                    onChanged(config.copyWith(borderEnabled: value)),
              ),
              if (config.borderEnabled) ...[
                _ColorPalette(
                  selected: config.borderColor,
                  colors: _AvatarBuilderScreenState.borderColors,
                  onColor: (value) =>
                      onChanged(config.copyWith(borderColor: value)),
                  onCustom: () => customColor(
                    context,
                    config.borderColor,
                    (value) => onChanged(config.copyWith(borderColor: value)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Spessore'),
                    Expanded(
                      child: Slider(
                        value: config.borderWidth,
                        min: 1,
                        max: 12,
                        divisions: 11,
                        onChanged: (value) =>
                            onChanged(config.copyWith(borderWidth: value)),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text('${config.borderWidth.round()}px'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

class _ControlGroup extends StatelessWidget {
  const _ControlGroup({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _ShapeButton extends StatelessWidget {
  const _ShapeButton({
    required this.shape,
    required this.selected,
    required this.onTap,
  });
  final AvatarShape shape;
  final bool selected;
  final VoidCallback onTap;

  BorderRadius get radius => switch (shape) {
    AvatarShape.circle => BorderRadius.circular(18),
    AvatarShape.rounded => BorderRadius.circular(7),
    AvatarShape.squircle => BorderRadius.circular(12),
    AvatarShape.square => BorderRadius.circular(2),
  };

  @override
  Widget build(BuildContext context) => Tooltip(
    message: shape.name,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            borderRadius: radius,
          ),
        ),
      ),
    ),
  );
}

class _ColorPalette extends StatelessWidget {
  const _ColorPalette({
    required this.colors,
    required this.onColor,
    required this.onCustom,
    this.selected,
    this.gradientSelected = false,
    this.onGradient,
  });

  final List<int> colors;
  final int? selected;
  final bool gradientSelected;
  final ValueChanged<int> onColor;
  final VoidCallback onCustom;
  final VoidCallback? onGradient;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      if (onGradient != null)
        _ColorDot(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB)],
          ),
          selected: gradientSelected,
          onTap: onGradient!,
        ),
      for (final color in colors)
        _ColorDot(
          color: Color(color),
          selected: selected == color,
          onTap: () => onColor(color),
        ),
      _ColorDot(
        gradient: const SweepGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ),
        selected: false,
        onTap: onCustom,
        icon: Icons.colorize,
      ),
    ],
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.selected,
    required this.onTap,
    this.color,
    this.gradient,
    this.icon,
  });
  final bool selected;
  final VoidCallback onTap;
  final Color? color;
  final Gradient? gradient;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        gradient: gradient,
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: selected ? 3 : 1,
        ),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x28000000), blurRadius: 8)]
            : null,
      ),
      child: icon == null
          ? selected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null
          : Icon(icon, color: Colors.white, size: 17),
    ),
  );
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.label,
    required this.config,
    required this.onTap,
  });
  final String label;
  final AvatarBuilderConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      width: 68,
      child: Column(
        children: [
          AvatarBuilderPreview(config: config, overrideSize: 54),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.initial});
  final int initial;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late HSVColor color = HSVColor.fromColor(Color(widget.initial));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Colore personalizzato'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 74,
            decoration: BoxDecoration(
              color: color.toColor(),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 14),
          _slider(
            'Tonalità',
            color.hue,
            360,
            (value) => color = color.withHue(value),
          ),
          _slider(
            'Saturazione',
            color.saturation,
            1,
            (value) => color = color.withSaturation(value),
          ),
          _slider(
            'Luminosità',
            color.value,
            1,
            (value) => color = color.withValue(value),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ANNULLA'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, color.toColor().toARGB32()),
        child: const Text('USA COLORE'),
      ),
    ],
  );

  Widget _slider(
    String label,
    double value,
    double max,
    ValueChanged<double> update,
  ) => Row(
    children: [
      SizedBox(width: 88, child: Text(label)),
      Expanded(
        child: Slider(
          value: value,
          max: max,
          onChanged: (next) => setState(() => update(next)),
        ),
      ),
    ],
  );
}
