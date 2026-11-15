# Resile: Engineering Notebook

Game jam entry, theme **"bounce back"**. Team: **Nirvith (Nik)** and **Agastya**. Engine: **Godot 4.7.2**. Repository: `nirvith/resile`.

This notebook records what we built, what we decided, and **why**, so either of us can pick up the other's work, and so we can explain our choices to the judges. Newest work is added at the bottom of the decision log. Each entry says what was decided, why, what else we considered, and whether it still stands.

**Deadline (Sunday 15 November):** feature freeze 2:30 pm, soft submission 4:00 pm, final upload by 4:40 pm, hard deadline 5:00 pm.

---

## 1. The game in one page

**Pitch.** A janitor blob, fired and abandoned on a cargo spaceship, has to save it from aliens with a cleaning laser that only works after bouncing off the walls. His own bolts can knock pieces off him, and he has to gather himself back up to survive.

**Story beats.**
- Intro comic: the boss fires him, aliens board, the boss takes the last escape pod ("Don't scratch the floors."), the blob is alone with his cleaning laser.
- Between waves the boss radios in from the escape pod, going from insults to begging ("You're still fired, by the way." … "Okay, please save my ship. I'll give you a raise.").
- **Rock bottom:** a huge hit smashes the blob to one cell, the screen goes dark, the boss says nobody bounces back from that, and the player gathers his pieces back together. Planned to happen inside the boss fight.
- Ending: "Back at your desk Monday." The blob flies off with the ship. Final card: **"He bounced back."**

**Core rules.**
| Rule | Value | Where in code |
|---|---|---|
| Blob health | 8 cells | `character_body_2d.gd` (`max_cells`) |
| Hit | lose 1 cell, a chunk flies out, 0.5 s invulnerable | `take_damage` |
| Pick up a chunk | get the cell back | `chunk.gd` |
| Bolt | faint and harmless until its first bounce, then "live" | `bolt.gd` |
| Bolt life | 3 bounces, deleted on the 4th wall hit | `Max_bounces` |
| Bolt power-up | each bounce +15% speed and size; pierces enemies after 2 bounces | `SPEED_UP`, `PIERCE_AFTER` |
| Fire rate | one shot per 0.35 s, at most 3 bolts in the air ("the barrel") | `fire_rate_cooldown`, `max_bolts` |
| Live bolts | hurt enemies **and** the blob | `_on_hitbox_body_entered` |
| Pinball pad | bolt turns hot gold: speed ×1.6, 10 bounces, always pierces, cannot hurt the blob | `start_pinball` |
| Death | the current wave restarts | `waves.gd` |

---

## 2. Shared technical agreements

These are the rules both of us code against. Breaking one of them is the most likely cause of "it works in my scene but not in the game".

**Collision layers** (a body's *layer* is what it is; its *mask* is what it bumps into):
| Layer | Used by | Godot stores it as |
|---|---|---|
| 1 | Walls, furniture, pinball pads | `1` |
| 2 | The blob (player) | `2` |
| 3 | Enemies | `4` |
| 4 | Chunks | `8` |

| Thing | Layer | Mask | Why |
|---|---|---|---|
| Blob | 2 | 1 | stops at walls; walks through enemies and chunks |
| Bolt body | none | 1 | only bounces off walls; passes through everything else |
| Bolt `Hitbox` (Area2D) | none | 2, 3 | *senses* the blob and enemies without bouncing off them |
| Crawler / Glutton | 3 | 1, 3 | stop at walls and push against each other so they don't stack |
| Enemy bite area | none | 1, 2 | senses the blob |
| Chunk | 4 | 1 | bounces off walls only |
| Chunk `Pickup` | none | 2 | senses the blob |

**Groups** (a group is a name tag other code searches for):
| Group | Who has it | Used for |
|---|---|---|
| `player` | the blob (set in `player.tscn`) | enemies and waves find the blob |
| `enemies` | Crawler, Glutton (added in their script) | bolts know what to damage; waves know when a wave is cleared |
| `bolts` | every bolt | the 3-bolt barrel counts them; death clears them |
| `chunk` | every chunk | death clears them |
| `enemy_spawn` | the spawn markers in the map | waves pick where enemies appear |
| `pinball_pad` | the corner pads | a bolt knows it hit a pad |
| `camera` | the camera | anything can shake the screen |

**Function names:** anything that can be hurt has `take_damage(amount)`. The blob also has `gain_cell()` and `shatter(keep)`, and a signal `died`. The message box (Agastya, not built yet) must have `show_line(text)` and emit `finished`.

**Who owns which file** (to avoid two people editing the same scene, which Git merges badly):
| Nik | Agastya |
|---|---|
| `node_2d.tscn` (game scene), `player.tscn`, `character_body_2d.gd`, `bolt.*`, `chunk.*`, `waves.gd`, `camera.gd`, `sfx.gd` | `Crawler.tscn`, `Glutton.tscn`, `node_2d_1.gd` (enemy script), maps (`cargo_hold.tscn`, future levels), `pinball_pad.*`, title / intro / message box / ending scenes, `world.tscn` (scratch) |

---

## 2b. Visual style guide

Every colour has one meaning. If something new doesn't fit one of these roles, it should be slate.

| Colour | Hex | Meaning | Used on |
|---|---|---|---|
| Slate | `#2B3A4A` / `#5C6F82` | The ship | Walls, floor, furniture (the sci-fi pack's own colours) |
| Cyan | `#4FD6E6` | You | The blob, chunks, faint bolts, the player's HUD |
| Gold | `#FFC93C` (hot gold `#FFF0AA`) | Power / reward | Live bolts, pinball pads and pinball bolts, pickups, hazard stripes |
| Alien green | `#8CFF5A` (shader tint `0.55, 1, 0.35`) | Enemies | Every alien, via `art/alien.gdshader` |
| Alarm red | `#FF3D5A` | Danger / damage | Hurt flashes (blob and enemies), alarm lights, boss attacks |

**Text:** one pixel font everywhere (to be chosen by Agastya, set once in a Godot Theme); off-white on dark navy panels; gold for anything important.

**Screen layers:** the game world is on the default canvas, under a `CanvasModulate` colour grade. The vignette is a `CanvasLayer` on layer 1. **All UI (HUD, message box, menus) must use CanvasLayer layer 2 or higher**, so the vignette never darkens it and the colour grade never tints it.

---

## 3. Decision log

### Saturday 14 November

**D1. Collaborate through Git and GitHub, everyone on `main`, no branches.** *(~11 am)*
Why: two people and one weekend; branches and pull requests would cost more time than they save. We avoid conflicts by owning different files instead (see section 2).
Rules we adopted: pull before working; save in Godot → commit → pull → push, every time something works; never commit `.godot/` (it's a local cache); do commit `.import` and `.uid` files.

**D2. Godot 4.7, Compatibility renderer, nearest-neighbour texture filtering.** *(~2:20 pm)*
Why: Compatibility makes the editor look the same as a web export; nearest filtering keeps pixel art sharp instead of blurry.

**D3. Schedule with a hard "playable from title to ending" checkpoint, and a Sunday feature freeze.** *(~1:45 pm)*
Why: jam games most often fail by never being finished. The team chose to attempt the full scope, so the checkpoint and freeze are what protect the submission.

**D4. Mechanics first, art later.** *(~4 pm)*
Why: placeholder shapes let us find out early whether the game is fun; art made too early gets redone when the gameplay changes. Story screens were the exception: built early as plain text, because the judge weights storytelling highest.

**D5. Bolt rules: faint until the first bounce, 3 bounces, deleted on the 4th wall hit.** *(afternoon)*
Why: the theme. A shot only "comes back" with power after bouncing. It also forces aiming at walls instead of straight at enemies.

**D6. Adopt Agastya's naming: group `enemies`, function `take_damage(amount)`.** *(~7:40 pm)*
Why: we had agreed on `enemy` / `hit()` / `lose_cell()`, but the Crawler was already written with different names and worked. Changing our side was faster than rewriting his.

**D7. A bolt detects damage with a separate `Hitbox` (Area2D), not with its body.** *(~8 pm)*
Why: the bolt's body must only collide with walls so it bounces cleanly and faint bolts pass through enemies. An Area2D *senses* overlaps without physically colliding, so it can report "I touched an enemy / the blob" while the body keeps bouncing.
Considered: letting the body collide with enemies (Agastya's first version). Rejected because faint bolts would bounce off enemies, breaking rule D5.

**D8. Fire cooldown 0.35 s and a 3-bolt "barrel".** *(~9 pm)*
Why: without limits, spamming bolts was the best strategy and the bounce idea stopped mattering. The barrel makes each shot a decision. Implemented by counting nodes in the `bolts` group.

**D9. Crawler collision fixes: layer 3, collision shapes enlarged to cover the sprite, 1 health.** *(~9:50 pm – 3 am)*
Why: the Crawler was on layer 1 (so it counted as a wall), and its collision circle was about 8 px inside a much larger sprite, so bolts visibly passed through it. The design calls for one-hit Crawlers.

### Sunday 15 November

**D10. Cells as health; 0.5 s invulnerability after a hit; the blob shrinks as it loses cells.** *(~1 am)*
Why: health is literally pieces of the blob, which is what makes "pull yourself together" work. Invulnerability stops one bite from taking several cells.

**D11. Chunks paused at 1 am, rebuilt at 4:30 am.** 
Why paused: the first attempt was half-saved and causing confusion late at night. Why kept: chunks *are* the "bounce back" mechanic; they were never a cut.

**D12. Waves are data, run by an invisible `Waves` node; the blob emits `died` instead of restarting the room.** *(~1:20 am)*
Why: a list of waves means difficulty is tuned by editing numbers, not code. The signal keeps the blob from doing the level's job: the blob only announces it died; `Waves` decides what that means (clear the room, reset, restart the same wave).

**D13. Scope cuts.** *(~3:10 am)*
Cut: the Brute, the Glutton's chunk-eating, the second "bridge" map, size-changes-speed.
Why: we were about two hours behind; the cut items cost the most time for the least story value. Never cut: bolt rules, chunks, tutorial, boss lines, rock bottom, intro, ending.
(The bridge map and a boss came back in D21 as part of the level plan.)

**D14. Map built from sprites plus invisible collision, not a tilemap, for the walls.** *(~3:45 am)*
Why: the sci-fi pack's floor tiles are 256×256 squares, but **none of its wall pieces are square** (e.g. top wall 256×192, side walls 43×256). A tilemap can't paint them. The floor stays a tilemap; each wall is one Sprite2D with *Region* enabled and *Texture Repeat* on, so the piece repeats along the edge; collision is a separate unscaled `StaticBody2D`.

**D15. Enemy spawn markers in the map (group `enemy_spawn`).** *(~4:15 am)*
Why: random spawn points sometimes put enemies inside walls or on top of the blob. Markers let the map designer choose where aliens enter (vents, doors). The code falls back to random points if a map has no markers.

**D16. Bigger characters: scale the sprite and its collision shapes, never the physics body's root.** *(~4 am)*
Why: everything looked too small in the 1152×648 room. Scaling a physics body's root node is unreliable in Godot, so we scale the sprite node and enlarge the shapes by the same amount.

**D17. Follow camera at zoom 1.15, limited to the room, with screen shake.** *(~4 am)*
Why: a slight zoom makes things readable; a strong zoom would hide the walls players need for bank shots. Limits stop the camera showing outside the room. Shake lives on the camera so anything can call `get_tree().call_group("camera", "shake", amount)`.

**D18. Game feel package.** *(~4:30 am)*
Five generated sound effects (shoot, bounce, hit, hurt, pickup) through a global `Sfx` helper; bounce pitch rises with each bounce; a 0.05 s hit-stop freeze on each kill; screen shake on hurt, kills and pinball.
Why: sound and impact are the cheapest way to make a game feel finished and responsive.

**D19. Bolts power up with each bounce and pierce after 2 bounces.** *(~4:30 am)*
Why: before this, a bolt was equally good after 1 or 3 bounces, so players took the shortest shot. Rewarding longer ricochets makes clever shots feel great, which is the theme in mechanical form.

**D20. Glutton becomes a tougher variant (2 health, slower) instead of a chunk-eater; enemies spawn one at a time, 0.3 s apart.**
Why: the Glutton existed as a re-skinned Crawler; giving it 2 health adds variety for almost no work. Staggered spawns read better than a whole wave popping in at once. A `wave_id` counter stops an old spawn loop from continuing after the blob dies.

**D21. Design plan v3 (after playtesting showed the game was "boring").** *(4:40 – 4:55 am)*
Problems: an empty rectangular room makes every bounce the same; nothing changes as you progress.
Agreed:
- **Levels:** 3 levels × 3 waves, each level with its own map and a colour tint. Level 1 crawlers, level 2 obstacles and more enemies, level 3 a **boss fight with rock bottom inside it**.
- **Pinball pads** in the corners of each map (built in D23).
- **A HUD:** cell icons, the bolt barrel, level and wave, power-up timer, boss health bar.
- **Upgrades:** temporary power-up pickups themed as office perks ("Coffee break" = 7 s rapid fire, "Hard hat" = 4 s immunity) are recommended *instead of* the boss's permanent "bribes", because doing both costs ~2.5 h. **Decision pending.**
- If the boss fight hasn't started by 11 am, level 3 becomes a final hard wave with rock bottom at its start.

**D22. Cargo hold decorated.** *(~5 am)* See section 5 for how it is built.
Why: the room was flat and empty. Added: a grated maintenance border and hatch / drain floor tiles, a shadow under the top wall, wall-mounted props (electrical box, vents, storage label, caution sign, two red alarm lights with glow), floor grime and rust, a hazard-striped start zone around the blob, and furniture with collision along the walls (shelves, benches, crate stacks) plus two small crate columns flanking the start zone for cover and bank angles.
Props are drawn at 0.9–1.1× instead of the walls' 0.25× so they read next to the 96 px blob; this is a deliberate size mismatch for readability.

**D23. Pinball pads.** *(~5 am)* See section 5 for line-by-line code.
A glowing triangle in each corner (built pink, recoloured gold in D24). A bolt that hits one turns hot gold: speed ×1.6, 10 bounces, always pierces, **cannot hurt the blob**, leaves a trail. Only the first pad hit triggers it, so a bolt can't live forever by bouncing between pads.
Why: corners are hard to hit on purpose, so a pad hit is a skill shot with a big payoff: "bounce back stronger".
Balance risk: a pinball bolt can clear a wave alone. It still occupies one of the 3 barrel slots for its whole life. If it's too strong, lower `PINBALL_BOUNCES` to 6.

**D24. Visual cohesion pass: a five-colour palette where colour = meaning.** *(~5:35 am)*
Problem: the game looked "thrown together". Causes found: the bolt was the Godot logo (a placeholder); the enemies come from a fantasy art pack (an eyeball and a mushroom on a spaceship); objects are drawn at different pixel sizes; colours were picked one at a time and meant nothing.
Decision: the palette in section 2b, applied by role. Done in this pass:
- **Bolt** is now a 16×16 pixel orb (`art/bolt_orb.png`, white so code can tint it): cyan while faint, gold when live, hot gold in pinball mode.
- **All aliens** are recoloured to one green by a shader, so both art packs read as one species. Their hit flash is now palette red through the same shader.
- **Pinball pads** are gold (a reward), matching the pinball bolt.
- **The blob** flashes alarm red when hurt.
- **Colour grade + vignette:** a slight cool `CanvasModulate` over the world and a dark vignette around the screen edges. This is the standard jam trick for making art from different sources sit together.
Not done here (Agastya): one font and a Theme; using the palette for the comic, title, HUD and message box.
Considered: finding new art packs or redrawing enemies. Rejected: hours of work for the same effect the palette gives in one.
Known limit: the pixel-size mismatch between the blob, props and walls is reduced, not removed, without new art.

**D25. Level 2 map: the Control Deck (the boss's office).** *(~6 am)* See section 5.6 for how it is built.
Why this room: level 2's job (D21) is "obstacles and more enemies". Making it the boss's own office lets the map tell part of the story: it uses the pack's clean sterile set (F2 floor, W2 walls), because it's the floor he told you not to scratch. His desk sits in front of his office door with a "do not enter" sign.
What's in it:
- **Four wall islands** (192×48 each, solid on layer 1) around the start zone. Bolts bank off them exactly like walls, so the room becomes lanes and corner shots instead of one open box. This is what makes level 2 play differently from level 1.
- The boss's desk at the top, two benches on the side walls, the same four gold pinball pads in the corners, and the same hazard-striped start zone.
- Eight enemy spawn markers, placed so none is inside an obstacle.
- **Level tint stored in the map:** each map's root node carries `metadata/tint` (cargo hold `0.88, 0.93, 1` cool blue; control deck `1, 0.93, 0.84` warm amber). The level system can do `ColourGrade.color = map.get_meta("tint")` when it loads a map, so the colour lives with the map.
- **`level2_test.tscn`:** a copy of the game scene with the control deck in place of the cargo hold and the amber grade, so level 2 can be played now without touching `node_2d.tscn`. Delete it once the level system loads maps.
Known risk: enemies walk straight at the blob and slide along walls. An enemy directly behind an island can get stuck for a moment. If playtesting shows it's a problem, the cheap fix is to make flying Crawlers ignore the islands (a separate collision layer).
Considered: furniture-only obstacles (like level 1's crates). Rejected: furniture collision is only the lower part of each prop, so bank shots feel inconsistent. Islands are whole solid rectangles, so the angles are predictable.

**D26. Chunks are spawned with `call_deferred`.** *(~7 am, Nik)*
Bug: every hit printed `character_body_2d.gd:70 @ throw_chunk(): Can't change this state while flushing queries` (15 times in one playtest). A hit is reported during Godot's physics step; `throw_chunk` then added a chunk, which contains an Area2D, in the middle of that step. Godot refuses to add a collision area while it is checking collisions, so some chunks could end up with their pickup zone not working (you couldn't re-absorb them).
Fix: in `take_damage` and `shatter`, `throw_chunk.call_deferred()` / `throw_chunk.call_deferred(900)` instead of calling `throw_chunk()` directly. `throw_chunk` (no brackets) is the function itself; `.call_deferred()` runs it at the end of the frame, after physics. The delay is under 1/60 s.
Lesson (a typo we made on the way): `throw_chunk().call_deferred()` is wrong. The brackets run the function immediately (the original bug) and then try to call `.call_deferred()` on its empty result (`null`), which is a new error.
Rule from now on: anything that adds or removes physics objects (bodies, areas) from inside a collision signal or `take_damage` uses `call_deferred`.

---

## 4. How each system works (reference)

**`character_body_2d.gd` (the blob).** Moves with WASD (`Input.get_vector`, `move_and_slide`). Shoots on click if the cooldown has run out and fewer than 3 bolts exist: makes a bolt, adds it to the room *first*, then sets its position and direction (setting a global position before a node is in the scene causes errors). `take_damage` ignores hits while invulnerable, removes cells, throws one chunk per cell, plays a sound, shakes the camera, and emits `died` at 0. `throw_chunk` launches a chunk in a random direction (`Vector2.RIGHT.rotated(randf() * TAU)`). `shatter(keep)` is for rock bottom. `update_look` shrinks the sprite from 100% at 8 cells to 60% at 1 using `lerp`.

**`bolt.gd`.** See section 5.

**`chunk.gd`.** Moves with the velocity it was thrown with, bounces off walls, keeps 95% of its speed per physics tick (so it slides to a stop). After 0.4 s it checks every tick whether the blob is inside its `Pickup` area and not at full health; if so it calls `gain_cell()` and deletes itself. Checking every tick (instead of the `body_entered` signal) also catches a blob that was already standing on it.

**`waves.gd`.** Holds the waves as a list of dictionaries (`line` + `enemies`). `start_wave` makes the boss speak (`await say(...)`), then spawns that wave's enemies one at a time. `_physics_process` starts the next wave when a wave is running and no `enemies` are left; `running` stops this from triggering while the boss is still talking. `say` uses Agastya's message box if `res://message_box.tscn` exists, otherwise prints and waits 1.5 s. `spawn_point` picks a shuffled marker more than 250 px from the blob. `_on_player_died` clears enemies, bolts and chunks, resets the blob, and restarts the same wave without the line.

**`node_2d_1.gd` (enemy script, Agastya's).** Finds the blob by group, walks towards it (`direction_to`, `move_and_slide`), bites once per second while its `Area2D` overlaps the blob. Health comes from `max_health`; each spawn gets a random 80–120% speed so groups spread out. On death: hit-stop, small shake, `queue_free()`. On a non-lethal hit it flashes red: `set_flash` drives the alien shader's `flash` value from 1 to 0 with a tween.

**`camera.gd`.** Follows the blob each frame with smoothing, limited to the room, zoom 1.15. `shake(amount)` sets a strength that drains at 40 per second; each frame the view is offset randomly by up to that strength.

**`sfx.gd` (autoload `Sfx`).** `play(stream, volume_db, pitch)` creates a temporary `AudioStreamPlayer`, plays, and frees it when finished; pitch 0 means slightly random. `hit_stop(duration)` sets `Engine.time_scale` to 0.05 and waits on a timer that ignores time scale, then restores it.

---

## 5. Today's new code, line by line

### 5.1 How the map (`cargo_hold.tscn`) is put together

Godot draws children from top to bottom, so the order of nodes is the drawing order:

| Node | What it is | Why it's there |
|---|---|---|
| `Tiles` | TileMapLayer at scale 0.25 (256 px tiles → 64 px) | The floor. Four tile types: plain (F1), grated (F3) around the border, two hatches, two drains. |
| `FloorDecor` | Sprites with no collision | Grime, dirt, rust and a door marking at 60–80% opacity; four hazard-stripe strips around the blob's start zone (region + repeat, so each strip is exactly the right length). |
| `TopWallShadow` | A black Polygon2D at 27% opacity, 16 px tall, under the top wall | Gives the wall depth, so the floor looks like it sits below it. |
| `TopWall`, `BottomWall`, `LeftWall`, `RightWall` | Sprites with region + repeat (see D14) | The visible walls. |
| `WallDecor` | Sprites on the top wall, no collision | Electrical box, vents, "STOR" label, caution sign, two alarm lights with red glow sprites on top. |
| `Walls` | StaticBody2D with four rectangles: top 1152×48, bottom 1152×11, sides 11×648 | The real wall collision, matching the sprites exactly. Unscaled, because scaled physics bodies misbehave. |
| `Furniture` | One StaticBody2D per piece, each with a Sprite2D and a rectangle | Obstacles. The rectangle covers 90% of the width and the lower 65% of the height, because the art is drawn at a 3/4 angle: the top of a shelf is "behind" its base. |
| `PinballPads` | Four instances of `pinball_pad.tscn` (gold) | One per corner. They're the same scene rotated 0°, 90°, 180°, 270°. |
| `Spawn` | Marker2D at the centre | Where the blob starts (for future level loading). |
| `SpawnPoints` | Eight Marker2Ds in group `enemy_spawn` | Where enemies enter, all away from furniture and pads. |

The scene was generated from a layout list (positions and scales for every piece) and checked against a rendered preview before being written, so every collision box lines up with its sprite.

### 5.2 `pinball_pad.tscn`

```
PinballPad (StaticBody2D, layer 1)   ← counts as a wall
├─ Glow (Polygon2D)          a bigger, see-through gold triangle that pulses
├─ Pad (Polygon2D)           the solid gold triangle, 90×90 px
├─ Highlight (Polygon2D)     a lighter inner triangle, for a 3D look
├─ Edge (Line2D)             a white line along the long edge, where bolts hit
└─ CollisionPolygon2D        the same triangle as Pad: the physical shape
```
The triangle's right angle sits in the room's corner, so a bolt that flies into a corner hits the long edge at 45° and bounces back out into the room instead of getting stuck.

### 5.3 `pinball_pad.gd`, line by line

```gdscript
extends StaticBody2D
```
The pad is a StaticBody2D: a solid object that never moves. On layer 1, it behaves like a wall for everything.

```gdscript
const BASE_COLOR = Color("ffc93c")
const FLASH_TIME = 0.3
```
The pad's normal palette gold, and how long a hit flash lasts in seconds. Constants so they're easy to tune.

```gdscript
var time = 0.0
var flash_left = 0.0
```
`time` counts seconds since the pad appeared; it drives the pulse. `flash_left` is how much flash is left; 0 means no flash.

```gdscript
func _ready():
	add_to_group("pinball_pad")
```
Tags the pad so a bolt can check "did I hit a pinball pad?" with `is_in_group("pinball_pad")`.

```gdscript
func _process(delta):
	time += delta
	flash_left = max(flash_left - delta, 0.0)
```
Every frame: advance the clock, and count the flash down without going below 0.

```gdscript
	$Glow.modulate.a = 0.7 + 0.3 * sin(time * 4.0) + flash_left * 3.0
```
The glow's opacity. `sin(time * 4.0)` swings between −1 and 1 about every 1.5 s, so the glow breathes between 0.4 and 1.0. During a flash, `flash_left * 3.0` pushes it to full.

```gdscript
	$Pad.color = BASE_COLOR.lerp(Color.WHITE, flash_left / FLASH_TIME)
```
`lerp` blends two colours: 0 gives gold, 1 gives white. Right after a hit `flash_left / FLASH_TIME` is 1 (white), then it fades back to gold over 0.3 s.

```gdscript
func flash():
	flash_left = FLASH_TIME
```
Called by a bolt when it hits this pad; starts the flash.

### 5.4 `bolt.gd`, line by line (pinball parts are new)

```gdscript
const Max_bounces = 3
const PIERCE_AFTER = 2
const SPEED_UP = 1.15
const MAX_SPEED = 1500.0
const PINBALL_BOOST = 1.6
const PINBALL_BOUNCES = 10
```
Tuning numbers. `MAX_SPEED` is new: without a cap, a pinball bolt speeding up 15% per bounce for 10 bounces would reach about 4,000 px/s, too fast to see.

```gdscript
const BOUNCE_SOUND = preload("res://sounds/bounce.wav")
const HIT_SOUND = preload("res://sounds/hit.wav")
const PINBALL_SOUND = preload("res://sounds/pinball.wav")
```
Sounds loaded once when the game starts. `pinball.wav` is a quick rising five-note arpeggio, so a pad hit sounds like a pinball machine.

```gdscript
var speed = 600.0
var direction = Vector2.RIGHT
var bounces = 0
var max_bounces = Max_bounces
var live = false
var pinball = false
var trail
```
`speed` is a variable (not a constant) because it grows. `max_bounces` is a variable copy of `Max_bounces`, because pinball mode raises it to 10 for this one bolt only. `pinball` remembers whether this bolt is gold. `trail` holds the gold trail line; it stays empty for normal bolts.

```gdscript
func _ready():
	add_to_group("bolts")
	$Sprite2D.modulate = CYAN
	modulate.a = 0.5
```
Tag for the barrel count; start cyan and half see-through: faint and harmless (colours explained in 5.5).

```gdscript
func _physics_process(delta):
	var collision = move_and_collide(direction * speed * delta)
```
Move this tick's distance (speed × time since last tick) and get a report if a wall was hit.

```gdscript
	if trail:
		trail.add_point(global_position)
		if trail.get_point_count() > 14:
			trail.remove_point(0)
```
For pinball bolts only: add the current position to the trail and drop the oldest point once there are more than 14, so the trail follows the bolt like a tail of fixed length.

```gdscript
	if collision:
		var hit = collision.get_collider()
```
If we hit something, `get_collider()` tells us what: a wall, furniture, or a pad.

```gdscript
		if hit.is_in_group("pinball_pad") and not pinball:
			start_pinball(hit)
```
First time this bolt hits a pad: switch to pinball mode. `not pinball` means a gold bolt hitting another pad just bounces normally, so no bolt can live forever.

```gdscript
		elif bounces >= max_bounces:
			queue_free()
			return
```
Otherwise, if it has used up its bounces, delete it. Because the pad check comes first, a normal bolt on its last bounce that hits a pad is saved and goes gold instead of disappearing.

```gdscript
		direction = direction.bounce(collision.get_normal())
		bounces += 1
```
Reflect off the surface (the normal is the direction the surface faces) and count the bounce.

```gdscript
		speed = min(speed * SPEED_UP, MAX_SPEED)
		if $Sprite2D.scale.x < MAX_ORB_SCALE:
			$Sprite2D.scale *= SPEED_UP
```
15% faster per bounce, never above the cap. The orb grows too, until it's twice its starting size, so a 10-bounce bolt doesn't become huge.

```gdscript
		Sfx.play(BOUNCE_SOUND, -8.0, 1.0 + min(bounces, 8) * 0.12)
```
Bounce sound, quieter than the rest (−8 dB), with pitch rising 12% per bounce (capped after 8), so you hear the bolt charge up.

```gdscript
		if not live:
			live = true
			modulate.a = 1.0
			$Sprite2D.modulate = GOLD
```
First bounce makes the bolt dangerous, fully visible, and gold.

```gdscript
func start_pinball(pad):
	pinball = true
	live = true
	bounces = 0
	max_bounces = PINBALL_BOUNCES
```
Switch on pinball mode, make sure it's live, and give it a fresh count of 10 bounces.

```gdscript
	speed = min(speed * PINBALL_BOOST, MAX_SPEED)
	$Sprite2D.modulate = PINBALL_COLOR
```
The dramatic speed jump, and turn the orb hot gold so the player sees it happened.

```gdscript
	pad.flash()
	Sfx.play(PINBALL_SOUND, -2.0, 1.0)
	get_tree().call_group("camera", "shake", 3)
```
Feedback: the pad flashes white, the jingle plays at normal pitch, and the screen gives a small kick.

```gdscript
	trail = Line2D.new()
	trail.top_level = true
	trail.width = 6.0
	trail.default_color = Color(GOLD, 0.5)
	add_child(trail)
```
Create the trail line in code. `top_level = true` means its points are in room coordinates instead of moving with the bolt; otherwise the whole trail would travel along with the bolt instead of staying behind it. It's added as a child so it's deleted together with the bolt.

```gdscript
func _on_hitbox_body_entered(body: Node2D) -> void:
	if not live:
		return
```
Runs when the bolt's Hitbox touches the blob or an enemy. Faint bolts do nothing.

```gdscript
	if body.is_in_group("enemies"):
		Sfx.play(HIT_SOUND, -2.0)
		body.take_damage(1)
		if bounces < PIERCE_AFTER and not pinball:
			queue_free()
```
Hit an enemy: sound, 1 damage. The bolt disappears unless it has bounced at least twice **or** is a pinball bolt; those pierce through and keep going.

```gdscript
	elif body.is_in_group("player") and not pinball:
		body.take_damage(1)
```
Live bolts hurt the blob too (that's the risk in the design), **except** pinball bolts, which are safe, so a gold bolt is pure reward.

### 5.5 Visual cohesion pass (D24), line by line

**`bolt.gd`: colour by state.** New constants:
```gdscript
const CYAN = Color("4fd6e6")
const GOLD = Color("ffc93c")
const PINBALL_COLOR = Color("fff0aa")
const MAX_ORB_SCALE = 3.0
```
`Color("4fd6e6")` builds a colour from a hex code, so the code uses exactly the palette's values. `MAX_ORB_SCALE` replaces the old 0.3 cap, because the new orb's starting scale is 1.5 (16 px × 1.5 = 24 px).

```gdscript
	$Sprite2D.modulate = CYAN
	modulate.a = 0.5
```
In `_ready`: the orb is tinted cyan (the picture is white, so the tint is exactly its colour), and the whole bolt is half see-through: faint and harmless.

```gdscript
			$Sprite2D.modulate = GOLD
```
On the first bounce, next to `live = true`: the orb turns gold, the "power" colour.

```gdscript
	$Sprite2D.modulate = PINBALL_COLOR
	...
	trail.default_color = Color(GOLD, 0.5)
```
In `start_pinball`: hot gold, and a half-transparent gold trail. Only the sprite is tinted now (before, `modulate` tinted the whole bolt including the trail). `Color(GOLD, 0.5)` means "gold with 50% opacity".

**`art/alien.gdshader`: one species.**
```glsl
shader_type canvas_item;
```
A shader for 2D drawing. It runs for every pixel of the sprite it's attached to.
```glsl
uniform vec4 tint : source_color = vec4(0.55, 1.0, 0.35, 1.0);
uniform vec4 flash_color : source_color = vec4(1.0, 0.24, 0.35, 1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
```
Settings that can be changed from the editor or code: the alien green, the flash red, and how much flash to show (0 to 1).
```glsl
	vec4 tex = texture(TEXTURE, UV);
	float brightness = dot(tex.rgb, vec3(0.299, 0.587, 0.114));
```
Read this pixel's original colour, and turn it into a single brightness value. The three numbers are the standard weights for how bright the eye sees red, green and blue.
```glsl
	vec3 alien = clamp(0.12 + brightness * 1.8, 0.0, 1.0) * tint.rgb;
```
Repaint the pixel in green, keeping its light and dark detail: bright parts become bright green, dark parts dark green. `+ 0.12` and `* 1.8` brighten it, because the flying eye's original art is very dark; `clamp` keeps the value between 0 and 1.
```glsl
	vec3 final_colour = mix(alien, flash_color.rgb, flash);
	COLOR = vec4(final_colour, tex.a) * COLOR;
```
Blend towards red by the `flash` amount, keep the original transparency, and multiply by `COLOR` so normal node tinting still works.

**`Crawler.tscn`:** the `AnimatedSprite2D` uses a `ShaderMaterial` with this shader and **`resource_local_to_scene = true`**. That setting gives every spawned enemy its own copy of the material; without it, all enemies share one, and hitting one would flash every enemy on screen. The Glutton is built from the Crawler scene, so it inherits all of this.

**`node_2d_1.gd`: the hit flash.**
```gdscript
	set_flash(1.0)
	create_tween().tween_method(set_flash, 1.0, 0.0, 0.15)
```
Flash fully red, then let a tween call `set_flash` with values sliding from 1 to 0 over 0.15 s. The old version set `modulate` to red and back to white, which would have wiped out the green.
```gdscript
func set_flash(amount: float) -> void:
	sprite.material.set_shader_parameter("flash", amount)
```
Passes the value into the shader's `flash` setting.

**`character_body_2d.gd`: the blob's hurt flash.**
```gdscript
const ALARM_RED = Color("ff3d5a")
...
	$Sprite.self_modulate = ALARM_RED
	create_tween().tween_property($Sprite, "self_modulate", Color.WHITE, 0.25)
```
On a hit, the blob turns red and fades back over 0.25 s. It uses `self_modulate` rather than `modulate` because the invulnerability blink already changes `modulate`'s transparency every frame; two separate properties don't fight each other.

**`node_2d.tscn`: colour grade and vignette.**
- `ColourGrade` (CanvasModulate, colour `0.88, 0.93, 1`): multiplies every colour in the world slightly towards cool blue. It pulls art from different packs into one lighting mood. Later, each level can change this colour for its tint.
- `ScreenEffects` (CanvasLayer, layer 1) → `Vignette` (TextureRect filling the screen, ignoring the mouse): shows a `GradientTexture2D` with a radial fill, see-through in the middle and 55% dark navy at the edges. Being on a CanvasLayer, it stays fixed to the screen while the camera moves.

**`pinball_pad.tscn` / `.gd`:** colours changed to gold (`ffc93c` pad, `fff0aa` highlight, white edge, gold glow). The flash code is unchanged: it still blends the pad to white when hit.

---

### 5.6 How the level 2 map (`control_deck.tscn`) is put together (D25)

It was generated by the same kind of script as the cargo hold (`gen_level2.py`, outside the repo), so the scene and a preview image come from one set of numbers. In the editor it's ordinary nodes; change anything by hand.

| Node | What it is | Why |
|---|---|---|
| `ControlDeck` (root, Node2D) | Has `metadata/tint = Color(1, 0.93, 0.84, 1)` | The level's colour grade travels with the map (see D25). Read it with `get_meta("tint")`. |
| `Tiles` | TileMapLayer, scale 0.25, sources 3 = F2 floor, 4 = F2 access panel at (3,3) and (14,7), 5 = F2 drain at (14,3) and (3,7) | Same 18×11 grid of 64 px cells as the cargo hold. Clean floor: no grates, no grime. |
| `FloorDecor` | An arrow pointing at the boss's desk, the door marking at the bottom, the four hazard-stripe sprites around the start zone (426,230, 300×190) | The start zone looks the same in every level so the player always knows where they begin. |
| `TopWallShadow` | Black 27% strip under the top wall | Same depth trick as level 1. |
| `TopWall`, `BottomWall`, `LeftWall`, `RightWall` | W2 sterile wall pieces, *Region* + *Texture Repeat*, scale 0.25 | Same method as level 1 (D14), just the lighter wall set. |
| `WallDecor` | Office door, OFC and CTRL labels, do-not-enter sign, two security cameras, a vent, two red alarm lights with glow | The door and sign say "this is the boss's office" without any text box. |
| `Walls` (StaticBody2D) | The same four collision rectangles as level 1 | Room size and edges are identical, so the camera limits and pads work unchanged. |
| `Obstacles/IslandTopLeft` … `IslandBottomRight` | Each a StaticBody2D at (256,200), (896,200), (256,448), (896,448) | Layer 1 like every wall, so bolts, the blob and enemies all collide with it. |
| └ `Shadow` | Polygon2D, 16 px dark strip under the island | Makes it read as a raised block, not a painting on the floor. |
| └ `Face` | W2 top wall piece repeated 3 times (`Rect2(0, 0, 768, 192)` at 0.25 = 192×48) | The light top edge plus the wall face. |
| └ `EdgeLeft`, `EdgeRight` | W2 side pieces cropped to 48 px tall | Gives the island ends instead of a cut-off strip. |
| └ `CollisionShape2D` | One rectangle 192×48, centred | The whole visible block is solid, so bank angles are exactly what you see. |
| `Furniture/BossDesk` | `bench_F_filled` at (576,128), scale 1.0 | Cover at the top, and the story prop. Collision is the lower 65%, like all furniture. |
| `Furniture/BenchWestWall`, `BenchEastWall` | `bench_side` at (50,324) and (1102,324) | Break up the long side walls. |
| `PinballPads` | Four `pinball_pad.tscn` instances, same corners and rotations as level 1 | Pads are a rule of every level (D21). |
| `Spawn` | Marker2D at (576,324) | Blob start. |
| `SpawnPoints/Enemy1–8` | Marker2D in group `enemy_spawn` at (100,140), (440,110), (712,110), (1052,140), (1060,520), (712,560), (440,560), (100,520) | Moved from level 1's spots so none is inside an island or the desk. `waves.gd` already uses this group. |

**`level2_test.tscn`:** `node_2d.tscn` copied with three changes: the map instance points to `control_deck.tscn`, the root is renamed `Level2Test`, and `ColourGrade` is amber. Open it and press F6 (Run Current Scene) to play level 2.

**`cargo_hold.tscn`:** one line added to the root, `metadata/tint = Color(0.88, 0.93, 1, 1)`, so both maps work the same way.

---

## 6. Open items

- **Pending decision:** power-up pickups instead of bribes (recommended), or both.
- **Nik:** tutorial; level system (3 × 3 with tints); boss fight with rock bottom; HUD wiring; pickups.
- **Agastya:** message box (`show_line` / `finished`, on CanvasLayer layer 2+) first; one pixel font and a Theme; palette for comic, title, HUD and message box; ending; title → intro → game flow; level 2 map built (D25), needs a playtest; level 3 (boss) map; HUD layout; comic art; music; export templates; submission page and credits.
- **Level system (Nik):** when loading a map, set `ColourGrade.color = map.get_meta("tint")`; then delete `level2_test.tscn`.
- **Tuning to check in playtests:** pinball strength, wave sizes, Glutton health, fire rate, camera zoom.
- **Title** still undecided (two words max). Shortlist: Overtime, Unglued, Rage Quit, Clocked Out, Out of Office.
