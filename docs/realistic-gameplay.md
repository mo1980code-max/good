# Realistic hand and touch gameplay

The spa and studio no longer use a geometric hand painter.

## Asset

`assets/images/hand/realistic_hand.png` is a transparent, top-down hand asset
with natural fingers, thumb separation, nail beds, skin folds and soft studio
shading. `RealisticHandPreview` is the shared renderer used by Spa, Studio,
Reveal and Album. `SkinTone` applies a colour grade without discarding the
source detail.

## Spa coverage

`RoundController.rubAlong` receives the start and end of each drag segment. It
samples the segment, accepts only points inside the normalized palm/finger
mask, and fills a set of hand cells. A tap has no segment and cannot complete a
stage. Each stage adds its own live layer:

- cleaning: dirt fades according to scrub coverage;
- soap: transparent bubbles grow and highlight;
- rinse: animated blue streams and droplets;
- dry: towel-following highlights;
- cream: glossy moisturiser glow.

The `SpaToolVisual` follows the pointer and changes from pore-textured sponge
to pump bottle, rinse nozzle, woven towel and cream tube. The existing audio
engine remains the only sound authority, so brush, bubble, water and sparkle
cues retain their throttle and mute behaviour.

## Studio coverage

The studio loads a live `PolishBottleVisual`. Selecting a bottle only loads the
brush. `RealisticHandPreview` recognizes five normalized natural nail regions
and emits `NailBrushEvent` values while the child drags. `RoundController.paintNail`
adds coverage from movement distance; the nail painter clips a glossy gradient,
pattern and highlight to a curved nail path. A stationary tap adds zero
coverage. Long-pressing a nail removes its colour so it can be repainted.

The current brush colour and five nail colours are in memory during the round.
On completion, `GalleryItem.nailColors` and `nailLengthId` are saved alongside
the existing recipe with backward-compatible parsing. Old gallery saves still
render as a single colour.

## Child-safe controls

- Skin-tone swatches are large and visible in both rooms.
- Short, medium and long nail lengths are independent from round, square and
  almond shapes.
- Spa stages have an explicit Skip action with no reward penalty.
- Existing characters, rewards, album persistence, audio controls and grown-up
  gate are unchanged.
