import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_config.dart';
import 'package:spendwise/presentation/settings/avatar/avatar_service.dart';

class AvatarCustomizerView extends StatefulWidget {
  const AvatarCustomizerView({
    required this.userId,
    required this.initialConfig,
    super.key,
  });

  final String userId;
  final AvatarConfig initialConfig;

  @override
  State<AvatarCustomizerView> createState() => _AvatarCustomizerViewState();
}

class _AvatarCustomizerViewState extends State<AvatarCustomizerView> {
  late AvatarConfig config = widget.initialConfig;
  bool saving = false;

  void update(AvatarConfig value) => setState(() => config = value);

  Future<void> save() async {
    setState(() => saving = true);
    try {
      await AvatarService.saveAvatarConfig(widget.userId, config);
      if (mounted) Navigator.pop(context, config);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> reset() async {
    await AvatarService.resetAvatarConfig(widget.userId);
    update(
      AvatarService.generateAvatarFromUserId(
        widget.userId,
        widget.initialConfig.initials,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Personalizza Avatar'),
      actions: [
        TextButton.icon(
          onPressed: reset,
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset'),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final preview = _AvatarPreview(config: config);
        final controls = _AvatarControls(config: config, onChanged: update);
        if (desktop) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 360, child: preview),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: controls,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return Column(
          children: [
            _CompactAvatarPreview(config: config),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: controls,
              ),
            ),
          ],
        );
      },
    ),
    bottomNavigationBar: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: FilledButton.icon(
          onPressed: saving ? null : save,
          icon: saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: const Text('SALVA AVATAR'),
        ),
      ),
    ),
  );
}

class _CompactAvatarPreview extends StatelessWidget {
  const _CompactAvatarPreview({required this.config});
  final AvatarConfig config;

  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surface,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    child: Row(
      children: [
        Container(
          width: 104,
          height: 104,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: SvgPicture.string(AvatarService.generateAvatarSvg(config)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.gender == 'female' ? 'Profilo Donna' : 'Profilo Uomo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                config.initials.isEmpty
                    ? 'Anteprima sempre visibile'
                    : 'Iniziali ${config.initials.toUpperCase()}',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.config});
  final AvatarConfig config;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('Anteprima', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          Container(
            width: 260,
            height: 260,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SvgPicture.string(
              AvatarService.generateAvatarSvg(config),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            config.initials.isEmpty
                ? 'Profilo SpendWise'
                : 'Avatar ${config.initials}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'SVG inline · leggero · responsive',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _AvatarControls extends StatelessWidget {
  const _AvatarControls({required this.config, required this.onChanged});
  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SectionCard(
        icon: Icons.person_outline,
        title: 'Persona',
        child: Column(
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'male',
                  icon: Icon(Icons.male),
                  label: Text('Uomo'),
                ),
                ButtonSegment(
                  value: 'female',
                  icon: Icon(Icons.female),
                  label: Text('Donna'),
                ),
              ],
              selected: {config.gender},
              onSelectionChanged: (value) => onChanged(
                config.copyWith(
                  gender: value.first,
                  beardStyle: value.first == 'female'
                      ? 'none'
                      : config.beardStyle,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: config.initials,
              maxLength: 2,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Iniziali',
                hintText: 'AC',
                prefixIcon: Icon(Icons.text_fields),
              ),
              onChanged: (value) => onChanged(config.copyWith(initials: value)),
            ),
          ],
        ),
      ),
      _SectionCard(
        icon: Icons.palette_outlined,
        title: 'Colori',
        child: Column(
          children: [
            _PaletteRow(
              label: 'Principale',
              selected: config.primaryColor,
              colors: const [
                '#2563eb',
                '#14b8a6',
                '#7c3aed',
                '#d97706',
                '#db2777',
              ],
              onChanged: (value) =>
                  onChanged(config.copyWith(primaryColor: value)),
            ),
            _PaletteRow(
              label: 'Sfondo',
              selected: config.backgroundColor,
              colors: const [
                '#e1effe',
                '#dff4ef',
                '#eee7fb',
                '#fff0d5',
                '#f7e7ef',
              ],
              onChanged: (value) =>
                  onChanged(config.copyWith(backgroundColor: value)),
            ),
          ],
        ),
      ),
      _SectionCard(
        icon: Icons.face_retouching_natural,
        title: 'Aspetto',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ChoiceWrap(
              label: 'Tono pelle',
              value: config.skinTone,
              options: const {
                'porcelain': 'Porcellana',
                'light': 'Chiaro',
                'medium': 'Medio',
                'tan': 'Ambrato',
                'deep': 'Scuro',
              },
              onChanged: (value) => onChanged(config.copyWith(skinTone: value)),
            ),
            _ChoiceWrap(
              label: 'Capelli',
              value: config.hairStyle,
              options: config.gender == 'female'
                  ? const {
                      'initials': 'Solo iniziali',
                      'short_01': 'Pixie',
                      'medium_01': 'Caschetto',
                      'long_01': 'Lunghi',
                    }
                  : const {
                      'initials': 'Solo iniziali',
                      'short_01': 'Corti',
                      'medium_01': 'Medi',
                      'long_01': 'Lunghi',
                    },
              onChanged: (value) =>
                  onChanged(config.copyWith(hairStyle: value)),
            ),
            _ChoiceWrap(
              label: 'Colore capelli',
              value: config.hairColor,
              options: const {
                'black': 'Nero',
                'brown': 'Castano',
                'blonde': 'Biondo',
                'auburn': 'Ramato',
                'silver': 'Argento',
              },
              onChanged: (value) =>
                  onChanged(config.copyWith(hairColor: value)),
            ),
            _ChoiceWrap(
              label: 'Outfit',
              value: config.outfit,
              options: const {
                'shirt_01': 'Blazer',
                'sweater_01': 'Maglia minimal',
              },
              onChanged: (value) => onChanged(config.copyWith(outfit: value)),
            ),
          ],
        ),
      ),
      _SectionCard(
        icon: Icons.auto_awesome_outlined,
        title: 'Accessori',
        child: Column(
          children: [
            if (config.gender == 'male')
              _ChoiceWrap(
                label: 'Barba / baffi',
                value: config.beardStyle,
                options: const {
                  'none': 'Nessuna',
                  'short': 'Barba corta',
                  'mustache': 'Baffi',
                },
                onChanged: (value) =>
                    onChanged(config.copyWith(beardStyle: value)),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.visibility_outlined),
              title: const Text('Occhiali'),
              value: config.glasses,
              onChanged: (value) => onChanged(config.copyWith(glasses: value)),
            ),
          ],
        ),
      ),
      _SectionCard(
        icon: Icons.circle_outlined,
        title: 'Badge stato',
        child: _ChoiceWrap(
          label: 'Visibilità',
          value: config.statusBadge,
          options: const {
            'none': 'Nessuno',
            'online': 'Online',
            'offline': 'Offline',
          },
          onChanged: (value) => onChanged(config.copyWith(statusBadge: value)),
        ),
      ),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label, value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options.entries)
              ChoiceChip(
                label: Text(option.value),
                selected: value == option.key,
                onSelected: (_) => onChanged(option.key),
              ),
          ],
        ),
      ],
    ),
  );
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onChanged,
  });
  final String label, selected;
  final List<String> colors;
  final ValueChanged<String> onChanged;

  Color colorFromHex(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        SizedBox(width: 90, child: Text(label)),
        Expanded(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in colors)
                Tooltip(
                  message: color,
                  child: InkWell(
                    onTap: () => onChanged(color),
                    customBorder: const CircleBorder(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colorFromHex(color),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected == color
                            ? const [
                                BoxShadow(
                                  color: Color(0x30000000),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
