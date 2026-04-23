# Glassy Broken Effect Enhancement - April 23, 2026

## Improvements
- **Chromatic Aberration**: Implemented prismatic color splitting (Cyan/Magenta) on crack edges and flying shards to simulate light refraction through glass.
- **Internal Shard Detail**: Added pre-calculated frost points and facets to the large glass panes (`BrokenGlassPanePainter`).
- **Dynamic Glints**: Enhanced the shimmering sparkles that catch light as pieces tumble.
- **Multi-Tier Shattering**: Introduced a new `shrapnel` tier (medium-sized shards) in `PrismEntryPage` to bridge the gap between large panes and dust splinters.
- **Depth & Perspective**: Increased the Z-depth velocity and perspective scaling for a more dramatic 3D shatter feel.

## Technical Details
- Modified `prism_painters.dart` to include secondary color passes in `GlassCrackPainter` and `GlassShatterPainter`.
- Updated `BrokenGlassPaneData` to store pre-baked frost geometry.
- Balanced particle counts in `PrismEntryPage` for high-fidelity without performance degradation.
