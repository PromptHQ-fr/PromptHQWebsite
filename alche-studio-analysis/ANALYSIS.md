# Alche.studio - Analyse Technique Complete

## Stack Technique

| Technologie | Version | Role |
|-------------|---------|------|
| **Astro** | - | Framework SSR / SSG |
| **Three.js** | r177 | Rendu WebGL 3D |
| **GSAP** | 3.13.0 | Animations et ScrollTrigger |
| **Lenis** | 1.3.4 | Smooth scroll |
| **Howler.js** | - | Audio |
| **Lottie** | - | Animations vectorielles SVG |
| **Tweakpane** | 4.0.5 | Debug GUI (visible en dev) |
| **GLSL ES 3.00** | WebGL2 | Shaders custom |

---

## Architecture des Scenes

```
RenderPipeline
├── TopPageMainScene (scene 3D principale)
│   ├── MainLogo (logo "A" en glass 3D, GLTF)
│   ├── Grid (grille cylindrique avec cross-hairs)
│   ├── BGQuadTree (fond avec quad-tree instancie)
│   ├── AlcheLogo2D (logo plat "ALCHE")
│   └── WorksTitle (titre "WORKS")
│
├── TopPageMissionVisionScene (section Mission/Vision)
├── TopPageServiceScene (section Service)
├── ThumbnailScene (vignettes Works)
│
├── Post-Processing Pipeline:
│   ├── TopSceneMixer (melange les 3 scenes selon scroll)
│   ├── SubPageSceneMixer (pages secondaires)
│   ├── FXAA (anti-aliasing)
│   ├── Bloom (bright extract -> gaussian blur x3 -> composite)
│   └── FinalComposite (loading, thumbnails, tone mapping)
│
└── StableFluids (simulation GPU de fluides reactifs a la souris)
```

---

## 1. LE FOND (Background)

### BGQuadTree - Le systeme de fond principal
**Fichiers:** `shaders/quadtree/bgQuadTree.frag.glsl`, `shaders/quadtree/patterns.frag.glsl`

Le fond est un **quad-tree instancie** sur une surface cylindrique. C'est la piece maitresse du design visuel.

**Comment ca marche :**
1. **Geometrie:** Un `BoxGeometry` subdivise recursivement en quad-tree (profondeur max 3-4). Chaque "tuile" est une instance avec sa position, echelle, et un ID random.
2. **Instancing:** Utilise `InstancedBufferGeometry` pour le rendu performant de dizaines de tuiles.
3. **Cylindrical wrap:** Les tuiles sont disposees sur un cylindre (pas un plan plat) via `sin(theta)` et `cos(theta)` dans le vertex shader.
4. **Patterns:** 3 textures procedurales (patterns) generees en GPU qui sont mixees sur les tuiles :
   - **Pattern 1:** Bruit colore bleu/violet
   - **Pattern 2:** Grille binaire noir/blanc
   - **Pattern 3:** Melange HSV violet -> bleu glace -> orange feu
5. **Logo integre:** Le logo ALCHE est tile sur les cubes de 3 manieres differentes (defilant, duplique, vertical).
6. **Halftone dots:** Un pattern de demi-teinte est applique en overlay (`fract(vGlobalUv * 1800 * 0.23)`).
7. **Animation CRT:** L'effet "turn off" (fermeture comme un vieux TV) quand on quitte la section hero.

### Grille (Grid)
**Fichiers:** `shaders/grid/grid.vert.glsl`, `shaders/grid/grid.frag.glsl`, `shaders/grid/cross.frag.glsl`

- **Structure:** PlaneGeometry 64x64 segments wrappee en cylindre.
- **Grid lines:** Generees par `fract()` - lignes a 20% d'opacite.
- **Cross-hairs:** Petites croix aux intersections via instancing.
- **Scroll reactif:** La grille se deplace verticalement avec le scroll (fluids distortion en mode light).

### SubPage Background
**Fichier:** `shaders/background/bg.frag.glsl`

Pour les sous-pages (About, Works, etc.) : bruit colore avec vignette radiale et offset vers la gauche, dominante bleue sombre.

---

## 2. LE LOGO EN GLASS

### MainLogo - Effet verre/cristal
**Fichiers:** `shaders/main-logo/mainLogo.frag.glsl`, `shaders/main-logo/mainLogo.vert.glsl`

C'est LE composant star. Un modele GLTF du "A" d'Alche avec 3 meshes :
- `Alche_A` : Le mesh principal (verre)
- `Alche_Outline` : Le contour
- `Alche_SideScreen` : Les faces laterales (ecran)

**Technique du glass shader :**

1. **Refraction multi-sample (8 samples):** Pour chaque pixel, 8 rayons sont calcules avec des offsets aleatoires pour simuler un verre imparfait. Chaque sample a un leger decalage.

2. **Aberration chromatique:** Les canaux R, G, B sont echantillonnes a des UV differents (slide * 1.0, 2.0, 4.0), creant l'arc-en-ciel visible sur les bords.

3. **Roughness variable:** La rugosite vient d'une texture de bruit (`uNoiseTex`) echantillonnee a `uNoiseScale` (defaut: 9.0). Cela cree l'aspect "givre" ou "glace" non uniforme.

4. **Specular GGX:** Distribution de microfacettes GGX pour le highlight speculaire, avec une rugosite tres faible (0.003 + roughness * 0.4).

5. **Fresnel:** Approximation de Schlick (f0 = 0.1) pour les reflexions sur les bords.

6. **Environment map:** Un cubemap (`uEnvMap`) pour les reflexions de l'environnement, mixe via le Fresnel.

7. **Refraction de la scene:** Le shader lit la scene derriere le logo via `uTrnsTex` (transparent renderer texture), ce qui donne l'effet de voir a travers le verre.

### Outline & Screen Shaders
- **Outline:** Simple blanc opaque + base semi-transparente grise
- **Screen:** Les faces laterales du logo servent d'"ecran" pendant la section Service, avec distortion lens et bruit

### Rotation Interactive
Le logo reagit a :
- **Hover souris:** Rotation douce via lerping de quaternions
- **Scroll velocity:** Rotation proportionnelle a la vitesse de scroll (via Lenis)
- **Sections:** Chaque section (KV, Works, Vision, Service) a des parametres de rotation differents
- **Return to origin:** Le logo revient naturellement a sa position neutre (slerp vers identite)

**Parametres par section :**
```
default:  animationIntensity=0, baseRotationSpeed=0, returnToOriginForce=0.3
kv:       animationIntensity=0, baseRotationSpeed=0, returnToOriginForce=0.5
works:    animationIntensity=1, baseRotationSpeed=0.3, returnToOriginForce=0.8
service:  animationIntensity=0, baseRotationSpeed=0, returnToOriginForce=1.8
```

---

## 3. EFFETS DE LUMIERE

### Bloom (3 passes)
**Fichiers:** `shaders/post-processing/bloomBright.frag.glsl`, `shaders/post-processing/bloomBlur.frag.glsl`

Pipeline bloom classique :
1. **Bright pass:** Extrait les pixels au-dessus d'un seuil (0.9)
2. **Gaussian blur:** 3 niveaux de flou a des resolutions decroissantes (1/4, 1/8, 1/16)
3. **Composite:** Les 3 niveaux sont additionnes avec des poids croissants (0.5, 1.0, 1.5) * 0.15

### Stable Fluids (GPU Fluid Simulation)
**Fichiers:** `shaders/fluids/*.frag.glsl`

Simulation complete de Navier-Stokes sur GPU :
- **Advection:** Semi-lagrangien (trace back to source)
- **Curl + Vorticity confinement:** Preserve les tourbillons
- **Divergence + Pressure solve:** 4 iterations Jacobi
- **Gradient subtract:** Rend le champ incompressible
- **Velocity input:** La souris injecte de la velocite (rayon adaptatif avec le mouvement)

Les fluides affectent :
- La distortion des UV dans le scene mixer (0.01)
- La distortion dans le composite final (0.001)
- La couleur de la grille (en mode light)
- L'emission des faces laterales des quad-tree cubes
- Les transitions Mission/Vision

### Emission des cubes
Les faces laterales des cubes du quad-tree (`vSideFace`) emettent de la lumiere proportionnellement a la velocite des fluides (`vEmitSide = length(fluids.xy)`), creant un effet de "tranche lumineuse" quand on deplace la souris.

### Vignette
Appliquee a plusieurs niveaux :
- Scene principale : `smoothstep(1.2, 0.0, len)` (tres large)
- Mission/Vision : `smoothstep(1.5, 0.3, len)`
- QuadTree global : `smoothstep(0.55, 0.05, length(vGlobalUv - 0.5))`
- QuadTree local : `smoothstep(1.9, 0.1, length(vUv - 0.5))`

---

## 4. ANIMATIONS

### Scroll Management (topScrollManager)
Le scroll est divise en sections avec des triggers GSAP ScrollTrigger :

| Trigger | Section | Effet |
|---------|---------|-------|
| `kv` | Hero/KV | Logo 3D + grille + QuadTree patterns |
| `works_intro` | Transition vers Works | Works title fade in |
| `works_progress` | Works gallery | Scroll horizontal des thumbnails |
| `works_outro` | Fin Works | Transition camera perspective -> ortho |
| `mission_in` | Mission | Wipe vertical avec motion blur |
| `vision` | Vision | Logo rotation (0.15 * HPI) |
| `service_in` | Service | Logo morph en ecran plat |
| `stellla` | Stellla section | Video embed |

### Transitions entre sections
**TopSceneMixer** melange 3 render targets :
- **Main -> Mission/Vision :** Wipe vertical avec `smoothstep` et motion blur sinusoidal
- **Mission/Vision -> Service :** Hard cut (`step(0.9999, uVisibleService)`)

### Logo Animations
- **KV section:** Logo 3D libre, rotation par hover/scroll
- **Works section:** `animationIntensity=1`, rotation acceleree, `baseRotationSpeed=0.3`
- **Vision section:** Rotation `uVisionRotate * 0.15 * HPI` en XZ et `-0.1` en YZ
- **Service section:** Morph du logo 3D en position ecran plat via `uServiceRotate` (lerp ortho -> screen space)

### QuadTree Animations
- **Pattern transitions:** 3 types d'interpolation (instant, per-instance, sweep horizontal)
- **UV shift:** Decalage aleatoire des UV periodiquement (glitch effect)
- **BlackOut:** Certaines tuiles s'eteignent aleatoirement
- **CRT Turn-off:** Effect TV CRT quand on quitte le hero

### Lottie (Outro)
L'outro utilise Lottie pour une animation SVG du logo avec un gradient radial, combinees avec un WebGL canvas separé (OutroGL) qui genere un fond bruite anime.

### Smooth Scroll (Lenis 1.3.4)
- Gere le scroll natif avec interpolation
- La velocite du scroll (`lenis.velocity`) est capturee et utilisee pour :
  - Rotation du logo principal
  - Deplacement de la grille
  - Animation de la camera

### Loading Animation
Dans `finalComposite.frag.glsl` :
- Reveal circulaire avec distortion sinusoidale
- Le SVG de chargement est affiche pendant le loading
- Zoom progressif de 0.5 a 1.0
- Transition smooth vers le contenu

---

## Structure des Fichiers Extraits

```
alche-studio-analysis/
├── ANALYSIS.md                          <- Ce fichier
├── alche-screenshot.png                 <- Screenshot de la page
│
├── shaders/
│   ├── main-logo/
│   │   ├── mainLogo.frag.glsl          <- Glass/crystal refraction shader
│   │   ├── mainLogo.vert.glsl          <- Vertex avec rotation sections
│   │   ├── mainLogoOutline.frag.glsl   <- Contour blanc
│   │   └── mainLogoScreen.frag.glsl    <- Faces laterales "ecran"
│   │
│   ├── grid/
│   │   ├── grid.vert.glsl             <- Grid cylindrique + cross instancing
│   │   ├── grid.frag.glsl             <- Grid lines avec fluids
│   │   └── cross.frag.glsl            <- Cross-hair aux intersections
│   │
│   ├── background/
│   │   └── bg.frag.glsl               <- Fond bruit colore (sub-pages)
│   │
│   ├── quadtree/
│   │   ├── bgQuadTree.frag.glsl       <- Quad-tree fond principal
│   │   └── patterns.frag.glsl         <- 3 patterns proceduraux
│   │
│   ├── fluids/
│   │   ├── advect.frag.glsl           <- Semi-Lagrangian advection
│   │   ├── curl.frag.glsl             <- Curl du champ de velocite
│   │   ├── divergence.frag.glsl       <- Divergence calculation
│   │   ├── pressure.frag.glsl         <- Jacobi pressure solver
│   │   └── velocity.frag.glsl         <- Velocity + mouse input
│   │
│   ├── post-processing/
│   │   ├── bloomBright.frag.glsl       <- Extraction pixels lumineux
│   │   ├── bloomBlur.frag.glsl         <- Gaussian blur separable
│   │   ├── topSceneComposite.frag.glsl <- Composite final + bloom + ASCII
│   │   ├── topSceneMixer.frag.glsl     <- Mix des 3 scenes par scroll
│   │   ├── finalComposite.frag.glsl    <- Loading + thumbnails
│   │   └── fxaa.frag.glsl             <- Anti-aliasing
│   │
│   └── outro/
│       ├── noise.frag.glsl            <- Simplex noise 3D procedural
│       └── plane.frag.glsl            <- Fond anime outro
│
├── css/
│   ├── main-styles.css                 <- CSS principal
│   ├── about-styles.css                <- Styles About
│   ├── index2-styles.css               <- Styles Index
│   └── about2-styles.css               <- Styles About v2
│
└── bundle-beautified.js                <- JS complet beautifie (55K lignes)
```
