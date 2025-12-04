# Kabafuda Solitaire for PICO-8

A unique solitaire card game for PICO-8, based on the addictive Kabafuda
Solitaire variant from Zachtronics' Last Call BBS.

## Distribution Files

- **kabafuda.p8** - Single-file merged cartridge for distribution
- **main.p8** - Source cartridge with modular includes for development
- **\*.lua** - Individual module files (cards, input, rendering, validation, auto-moves)

## Game Rules

### Objective
Move all cards to the four foundation piles, building each pile from Ace to
King in a single suit.

### Layout
- **Stock**: Top-left pile containing undealt cards (no re-deals allowed)
- **Waste**: Next to stock, receives cards drawn from stock (3 at a time)
- **Foundations** (4): Top-right area, build Ace through King by suit
- **Tableau** (7): Bottom area with 7 columns, dealt 1-7 cards respectively

### Gameplay
1. **Drawing**: Click stock to draw 3 cards to waste pile
2. **Building Foundations**: Start with any Ace, then build up by suit (A-2-3...J-Q-K)
3. **Tableau Rules**: Build down by alternating colors (red on black, black on red)
4. **Moving Cards**: Only face-up cards can be moved; flip face-down cards when exposed
5. **Empty Stock**: When stock is depleted, its space becomes a single-card reserve

### Special Rules
- Stock can only be dealt through once (no re-deals)
- Must draw 3 cards at a time from stock
- Only the top card of waste pile is playable
- Empty tableau columns can be filled with any King

## Controls

- **D-Pad**: Move cursor between game areas
- **Up/Down**: Select cards in tableau (when not holding)
- **O Button**: Grab/place cards
- **X Button**: Return held cards to source

## Development

The project uses a modular structure for development:

1. **main.p8** - Main entry point with `#include` statements
2. **\*.lua files** - Individual modules for different game systems
3. **kabafuda.p8** - Merged single-file version created with `picomerge`

To rebuild the distribution file:
```bash
picomerge main.p8 kabafuda.p8
```

### Auto-merge Tool

This project uses [picomerge](https://github.com/0xcafed00d/picomerge) to automatically merge the modular source files into a single cartridge for distribution.

## Acknowledgements

This implementation is inspired by the brilliant solitaire variants found in
Zachtronics games, particularly "Last Call BBS" which featured the original
Kabafuda Solitaire. Zachtronics has created some of the most interesting and
addictive solitaire games, and this PICO-8 version aims to capture that same
compelling gameplay.
