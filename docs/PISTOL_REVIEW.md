# Pistol grip proposal — user review required

This dedicated change translates only the attached pistol by `(0.06, 0.015, 0.025)` metres in its local frame. Its handle sits farther inside the existing curled fingers. The pistol's child grip/muzzle markers move with it; barrel orientation, arm/finger animation, other weapons and private editable assets are unchanged.

Do not approve or merge this PR until the user reviews the before/after captures and explicitly accepts the result. The normal playable build retains the approved fit; the proposal has its own external candidate build.

The native 1280×800 Metal candidate passes 976 gameplay checks. A dedicated inspection captures front, side, rear and top views of lowered and aimed pistols on all four survivors. The baseline uses the same cameras and sampled poses with the approved player script. Source checks and screenshot evidence accompany the local candidate; physical devices/controllers are not implied by these tests.

After external assembly, reproduce the comparison views with:

```sh
ZOMBIE_REPORT_DIR="$ZOMBIE_HOME/verification/pistol-grip" \
  "$ZOMBIE_HOME/tools/Godot.app/Contents/MacOS/Godot" \
  --path "$ZOMBIE_HOME/workspace" --resolution 1280x800 -- \
  --inspection --pistol-only
```

Captures stay outside public Git, as do all embedded game assets and playable exports. Reverting this small runtime offset restores the previous fit without needing to roll back any rig or asset source.
