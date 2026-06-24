# HUD Stream Assets

Place a patched `minimap.gfx` in this folder to fully remove the native GTA
health/armor bars from the minimap. This server currently keeps that file local
at `resources/[extraction]/extraction_hud/stream/minimap.gfx`.

FiveM automatically streams files from a resource `stream` folder, so the file
does not need to be listed in `fxmanifest.lua`.

`minimap.gfx` is intentionally ignored by git because it is a modified GTA
scaleform binary. Keep it local/private and regenerate it when the GTA game
build changes.

Recommended patch/source:

1. Extract `update/update.rpf/x64/patch/data/cdimages/scaleform_minimap.rpf/minimap.gfx`
   from an up-to-date GTA V install.
2. Open it in JPEXS/FFDec.
3. In `SETUP_HEALTH_ARMOUR`, hide `HEALTH_ARMOUR_BAR_MC` after the ability clip
   is created so health/armor bars are removed without breaking satnav.

Reference:
https://forum.cfx.re/t/how-to-remove-the-health-and-armour-bars-from-the-minimap-both-gfx-edit-and-lua-code-methods/5226665
