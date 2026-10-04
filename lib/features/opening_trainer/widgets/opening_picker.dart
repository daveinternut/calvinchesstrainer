import 'package:calvinchesstrainer/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../../core/services/opening_book_service.dart';

/// Curated popular openings for quick access. The names are proper names of
/// openings and stay as they are in every language.
const _popularOpenings = [
  ('C50', 'Italian Game', '1. e4 e5 2. Nf3 Nc6 3. Bc4'),
  ('C60', 'Ruy Lopez', '1. e4 e5 2. Nf3 Nc6 3. Bb5'),
  ('B20', 'Sicilian Defense', '1. e4 c5'),
  ('B50', 'Sicilian Defense: Open', '1. e4 c5 2. Nf3 d6 3. d4'),
  ('C00', 'French Defense', '1. e4 e6'),
  ('B10', 'Caro-Kann Defense', '1. e4 c6'),
  ('B01', 'Scandinavian Defense', '1. e4 d5'),
  ('C42', "Petrov's Defense", '1. e4 e5 2. Nf3 Nf6'),
  ('D06', "Queen's Gambit", '1. d4 d5 2. c4'),
  ('D30', "Queen's Gambit Declined", '1. d4 d5 2. c4 e6'),
  ('D20', "Queen's Gambit Accepted", '1. d4 d5 2. c4 dxc4'),
  ('A45', "Indian Game", '1. d4 Nf6'),
  ('E60', "King's Indian Defense", '1. d4 Nf6 2. c4 g6'),
  ('D70', 'Gruenfeld Defense', '1. d4 Nf6 2. c4 g6 3. Nc3 d5'),
  ('E00', 'Nimzo-Indian Defense', '1. d4 Nf6 2. c4 e6 3. Nc3 Bb4'),
  ('A10', 'English Opening', '1. c4'),
  ('A04', "Reti Opening", '1. Nf3'),
  ('B06', 'Modern Defense', '1. e4 g6'),
  ('A40', "Queen's Pawn Game", '1. d4 e6'),
  ('C20', "King's Pawn Game", '1. e4 e5'),
];

/// The ECO letters with their localized category names.
List<(String, String)> _ecoCategories(AppLocalizations l10n) => [
      ('A', l10n.ecoFlankOpenings),
      ('B', l10n.ecoSemiOpenGames),
      ('C', l10n.ecoOpenGames),
      ('D', l10n.ecoClosedGames),
      ('E', l10n.ecoIndianDefenses),
    ];

class OpeningPicker extends StatefulWidget {
  final OpeningBookService bookService;
  final void Function(String pgn, String name) onSelected;

  const OpeningPicker({
    super.key,
    required this.bookService,
    required this.onSelected,
  });

  @override
  State<OpeningPicker> createState() => _OpeningPickerState();
}

class _OpeningPickerState extends State<OpeningPicker> {
  String _searchQuery = '';
  String? _expandedEco;

  /// The book may still be loading when the picker opens right after the
  /// screen; the load is shared, so this just waits for it. Null when there
  /// is nothing to wait for.
  late final Future<void>? _bookReady =
      widget.bookService.isLoaded ? null : widget.bookService.load();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              hintText: l10n.searchOpenings,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _bookReady == null
              ? _buildLists(l10n)
              : FutureBuilder<void>(
                  future: _bookReady,
                  builder: (context, snapshot) {
                    // A failed load still leaves the popular list; search
                    // and categories need the book.
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildLists(l10n);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLists(AppLocalizations l10n) => _searchQuery.isNotEmpty
      ? _buildSearchResults(l10n)
      : _buildBrowseView(l10n);

  Widget _buildSearchResults(AppLocalizations l10n) {
    final terms = _searchQuery
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final results = widget.bookService
        .getAllOpenings()
        .where((o) {
          final name = o.name.toLowerCase();
          final eco = o.eco.toLowerCase();
          return terms.every((t) => name.contains(t) || eco.contains(t));
        })
        .take(50)
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          l10n.noOpeningsFound,
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) => _buildOpeningTile(results[index]),
    );
  }

  Widget _buildBrowseView(AppLocalizations l10n) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l10n.popularOpenings,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        for (final (eco, name, pgn) in _popularOpenings)
          _buildOpeningTile(OpeningInfo(eco: eco, name: name, pgn: pgn)),
        const Divider(height: 24),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(
            l10n.browseByCategory,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
          ),
        ),
        for (final (letter, label) in _ecoCategories(l10n))
          _buildEcoCategory(letter, label),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEcoCategory(String letter, String label) {
    final isExpanded = _expandedEco == letter;
    return Column(
      children: [
        ListTile(
          title: Text(
            '$letter — $label',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () => setState(() {
            _expandedEco = isExpanded ? null : letter;
          }),
        ),
        if (isExpanded)
          ...widget.bookService
              .getAllOpenings(ecoPrefix: letter)
              .take(100)
              .map(_buildOpeningTile),
      ],
    );
  }

  Widget _buildOpeningTile(OpeningInfo opening) {
    return ListTile(
      leading: Container(
        width: 42,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          opening.eco,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        opening.name,
        style: const TextStyle(fontSize: 15),
      ),
      subtitle: Text(
        opening.pgn,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        widget.onSelected(opening.pgn, opening.name);
      },
    );
  }
}
