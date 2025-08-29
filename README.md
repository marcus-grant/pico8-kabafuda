# Kabafuda Solitaire for PICO-8

A unique solitaire card game for PICO-8, based on the addictive Kabafuda
Solitaire variant from Zachtronics' Last Call BBS.

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

## Acknowledgements

This implementation is inspired by the brilliant solitaire variants found in
Zachtronics games, particularly "Last Call BBS" which featured the original
Kabafuda Solitaire. Zachtronics has created some of the most interesting and
addictive solitaire games, and this PICO-8 version aims to capture that same
compelling gameplay.
