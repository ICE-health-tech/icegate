# Symmetric Petal Entry Animation Flow

This document outlines the animation sequence logic for the updated PrismEntryPage, featuring the 4-petal mandala logo and the cinematic shatter transition.

```mermaid
graph TD
    A[Start Animation] --> B[Phase 1: Assemble]
    B --> C{Logo Assembled?}
    C -- No --> B
    C -- Yes --> D[Phase 2: Glowing Pulse Loop]
    D --> E[Wait for Auth/User Action]
    E --> F[Phase 3: Fractal Crack Sequence]
    F --> G[Spider-web Branching Effect]
    G --> H[Phase 4: Impact & Shatter]
    H --> I[Shockwave Energy Ring Expansion]
    I --> J[Shard Dispersion & Glitch Effect]
    J --> K[Transition to Login Page]

    subgraph "Visual Details"
    G1[Variable Stroke Widths]
    G2[350+ Metallic Shards]
    G3[Chromatic Aberration Glitch]
    G4[Polished Chrome Glints]
    end

    G --> G1
    H --> G2
    J --> G3
    J --> G4
```

## Animation Components

### 1. Symmetric Petal Painter
- Draws 4 petals using quadratic Bezier curves.
- Strict 90-degree rotational symmetry.
- Metallic silver gradient (`0xFFC7C7CC` to `0xFF8E8E93`).

### 2. Fractal Crack Logic
- Generates branching offsets for a realistic "spider-web" break pattern.
- Animates from center to edges with varying intensity.

### 3. High-Fidelity Shatter
- **Shard Physics**: 350+ shards with random polygon geometry.
- **Visual FX**: 
    - **Chromatic Aberration**: Magenta/Cyan shifts during impact.
    - **Chrome Glints**: White specular highlights on shards.
    - **Shockwave**: Rapidly expanding radial gradient ring.

### 4. Silver & Black Theme
- **Background**: Deep jet-black gradient with tactical silver grid.
- **Components**: High-contrast silver borders and glassmorphic surfaces.
