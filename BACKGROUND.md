# Background System — BGQuadTree + Grid

## Overview

The background is a **cylindrical surface** covered with instanced 3D cube tiles (quad-tree subdivided) and a transparent grid overlay with crosshairs. It replicates the Alche Studio architecture but is currently static — no animation, no lighting effects, no patterns yet.

---

## Architecture

```
Camera (z=7, FOV 40)
│
├── BGQuadTree (instanced BoxGeometry cubes)
│   ├── Opaque, renders first
│   ├── Cylindrical wrap: radius = uScale.x/2 = 7
│   ├── Height: uScale.y * 1.5 = 15
│   └── ~100-300 tiles from quad-tree subdivision
│
├── Grid (PlaneGeometry 1x1, 64x64 segments)
│   ├── Transparent, depthWrite: false, renders on top
│   ├── Same cylindrical wrap as tiles
│   ├── Grid lines (0.12 alpha) + crosshairs (0.25 alpha)
│   └── Subtle scroll animation (uTime * 0.03)
│
└── Logo + Text (in front of cylinder)
```

---

## Quad-Tree Tile System

### Generation (JS)
- Base grid: **8 columns x 6 rows** (48 base cells)
- Recursive subdivision: max depth **3** (smallest tile = 1/64th of the surface)
- Split probability per depth: `[0.85, 0.6, 0.35, 0.2]`
- Each tile stores: `{ x, y, w, h }` in 0..1 UV space
- Produces **~100-300 tiles** per generation (random each reload)

### Instance Attributes
| Attribute | Type | Description |
|-----------|------|-------------|
| `aPos` | vec2 | Tile center in 0..1 UV space |
| `aScale` | vec2 | Tile width/height in 0..1 UV space |
| `aRand` | vec4 | 4 random floats per tile (for future pattern/animation) |

### Vertex Shader
1. Box vertex `[-0.5..0.5]` scaled to tile size with **0.92 gap factor**
2. Tile depth = `min(w, h) * 0.3` (smaller tiles are thinner)
3. **vSideFace** detection: `step(0.5, abs(normal.z))` — 1.0 for front/back, 0.0 for edges
4. Cylindrical wrap: `theta = uvX * PI`, position on cylinder `(sin(theta)*r, y*h, -cos(theta)*r)`

### Fragment Shader (current: minimal)
- Front faces: `vec3(0.04, 0.045, 0.06)` + per-tile variation via `vInstanceID.x`
- Side faces (edges): `vec3(0.08, 0.09, 0.12)` — brighter gaps between tiles
- Per-tile vignette: `smoothstep(1.9, 0.1, length((vUv-0.5)*2.0))`
- Global vignette: `smoothstep(0.55, 0.05, length(vGlobalUv-0.5))`

---

## Shared Cylinder Parameters

Both tiles and grid use the same cylinder:
```
uScale = vec3(14, 10, 1)
→ radius = 7 units
→ height = 15 units (10 * 1.5)
→ arc = PI radians (half cylinder, facing camera)
```

---

## Varyings Available for Future Use

| Varying | Type | Purpose |
|---------|------|---------|
| `vUv` | vec2 | Per-tile local UV (0..1 within each tile) |
| `vGlobalUv` | vec2 | Global position on cylinder surface |
| `vSideFace` | float | 1.0 = front face, 0.0 = side/edge face |
| `vInstanceID` | vec4 | 4 random values per tile |

---

## Planned Additions (in order)

### 1. Pattern Textures
Render 3 procedural patterns to offscreen RTs (matching Alche):
- **Pattern 1:** Blue/purple noise (`smoothstep` on noise channels * `vec3(0.3, 0.4, 0.6) * 2.0`)
- **Pattern 2:** Binary noise grid (`step(0.5, fract(noise.w * 9.0))`)
- **Pattern 3:** HSV color blend (purple base → ice blue → fire orange)

Sample `uPatternCurrent` / `uPatternNext` in tile frag, mix via `vPatternSelect` for transitions.

### 2. Halftone Dots Overlay
```glsl
float dotw = smoothstep(0.5, 0.2, length(fract(vGlobalUv * 1800.0 * 0.23) - 0.5));
dotw = mix(dotw, 1.0, 0.6) * 0.9;
col *= dotw;
```
CRT/TV texture over the tile faces.

### 3. Side Face Emission
Hook fluid velocity (or mouse velocity) to side face brightness:
```glsl
// vEmitSide driven by fluid sim or mouse proximity
col += (1.0 - vSideFace) * 0.8 * vEmitSide;
```
Creates glowing edges when interacting.

### 4. CRT Turn-Off Effect
Per-tile hide animation driven by `uHideQuad` uniform:
```glsl
float hideKv = smoothstep(0.0, 1.0, -vInstanceID.x + uHideQuad * 2.0);
vec2 flashUv = (vUv - 0.5) * vec2(1.0, 1.0 + hideKv * 50.0);
col *= step(length(flashUv.y) + hideKv * 0.9, 1.0);
```
Tiles collapse like an old TV turning off, staggered by instance ID.

### 5. Pattern Transitions
3 transition modes between patterns:
- **Instant:** All tiles switch at once
- **Per-instance:** Each tile switches at `vInstanceID.x` threshold
- **Sweep:** Horizontal wipe across the cylinder

### 6. Fluid Simulation Integration
GPU Navier-Stokes (advection, curl, pressure solve) feeding:
- Side face emission intensity
- UV distortion in scene mixer
- Grid color modulation
