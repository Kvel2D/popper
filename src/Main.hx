// TODO: optimize canvas update after removal

import haxegon.*;
import haxe.ds.Vector;

using haxegon.MathExtensions;
using Lambda;

@:publicFields
class Main {
// force unindent

static inline var SCREEN_WIDTH = 800;
static inline var SCREEN_HEIGHT = 400;
static inline var WORLD_SIZE = 400;
static inline var TILESIZE = 1;
static inline var STEP_TIMER_MAX = 4;

var step_timer = 0;
var stepping = true;
var max_id = 1;
var tutorial_timer = 10 * 60;

var world = Data.create2darray(WORLD_SIZE, WORLD_SIZE, 0);
var friendly_counts = Data.create2darray(WORLD_SIZE, WORLD_SIZE, 0);
var dominant_faction_counts = Data.create2darray(WORLD_SIZE, WORLD_SIZE, 0);
var dominant_factions = Data.create2darray(WORLD_SIZE, WORLD_SIZE, 0);
var positions = new Array<Vec2i>();
var just_appeared_timer = new Map<Int, Int>();

function new() {
    Gfx.resizescreen(SCREEN_WIDTH, SCREEN_HEIGHT);
    Gfx.clearscreeneachframe = false;
    Gfx.fillbox(0, 0, WORLD_SIZE, WORLD_SIZE, Col.GRAY);

    for (x in 0...WORLD_SIZE) {
        for (y in 0...WORLD_SIZE) {
            positions.push({x: x, y: y});
        }
    }
}

static inline function in_bounds(x: Int, y: Int): Bool {
    return 0 <= x && x < WORLD_SIZE && 0 <= y && y < WORLD_SIZE;
}

function set_cell(x: Int, y: Int, i: Int) {
    // Don't update if no change needed
    if (i == world[x][y]) {
        return;
    }

    Gfx.set_pixel(x, y, int_to_color(i));

    var old_i = world[x][y];
    world[x][y] = i;

    // Update friendly counts
    // If making cell non-empty, increment friendly_counts
    for (dx in -1...2) {
        for (dy in -1...2) {
            if (dx == 0 && dy == 0) {
                continue;
            }
            var x = x + dx;
            var y = y + dy;

            if (in_bounds(x, y)) {
                if (world[x][y] == old_i && world[x][y] != i) {
                    // Changing from friendly to enemy, so decrement                
                    friendly_counts[x][y]--;
                } else if (world[x][y] != old_i && world[x][y] == i) {
                    // Changing from enemy to friendly, so increment
                    friendly_counts[x][y]++;
                }
            }
        }
    }

    // Update cell's own friendly count
    var friendly_count = 0;
    for (dx in -1...2) {
        for (dy in -1...2) {
            if (dx == 0 && dy == 0) {
                continue;
            }
            var x = x + dx;
            var y = y + dy;

            if (in_bounds(x, y)) {
                if (world[x][y] == i) {
                    friendly_count++;
                }
            }
        }
    }
    friendly_counts[x][y] = friendly_count;

    // Update dominant faction count of all neighbors
    for (dx in -1...2) {
        for (dy in -1...2) {
            if (dx == 0 && dy == 0) {
                continue;
            }
            var x = x + dx;
            var y = y + dy;

            if (in_bounds(x, y)) {
                var counts = new Map<Int, Int>();

                for (ddx in -1...2) {
                    for (ddy in -1...2) {
                        if (ddx == 0 && ddy == 0) {
                            continue;
                        }
                        var x = x + ddx;
                        var y = y + ddy;

                        if (in_bounds(x, y)) {
                            var faction = world[x][y];
                            if (faction != 0) {
                                if (!counts.exists(faction)) {
                                    counts[faction] = 0;
                                }
                                counts[faction] = counts[faction] + 1;
                            }
                        }
                    }
                }

                var biggest_count = 0;
                var biggest_faction = 0;
                for (faction in counts.keys()) {
                    if (counts[faction] > biggest_count || biggest_faction == 0) {
                        biggest_count = counts[faction];
                        biggest_faction = faction;
                    }
                }

                dominant_factions[x][y] = biggest_faction;
                dominant_faction_counts[x][y] = biggest_count;
            }
        }
    }
}

var int_to_color_colors = [0 => Col.GRAY];
function int_to_color(x: Int): Int  {
    // Add new random color if new index
    if (!int_to_color_colors.exists(x)) {
        var r = Random.int(0, 255);
        var g = Random.int(0, 255);
        var b = Random.int(0, 255);
        var color = Col.rgb(r, g, b);
        int_to_color_colors[x] = color;
    }

    return int_to_color_colors[x];
}

function update_cell(x: Int, y: Int) {
    if (world[x][y] == 0) {
        // If empty, check chance to spawn based on count of friendly neighbors
        // if cell is empty, get dominant, if not empty, get the faction that is cell's friend
        if (dominant_factions[x][y] != 0) {
            var friendly_count = dominant_faction_counts[x][y];
            var spawn_chance = Math.floor(friendly_count / 8 * 100);

            if (Random.chance(spawn_chance)) {
                set_cell(x, y, dominant_factions[x][y]);
            }
        }
    } else {
        // If non-empty, check chance to die based on count of friendly neighbors
        if (friendly_counts[x][y] != 8) {
            var die_chance = Math.floor(((8 - friendly_counts[x][y]) / 8 * 100) / 2);

            if (just_appeared_timer.exists(world[x][y])) {
                die_chance = 0;
            }

            if (Random.chance(die_chance)) {
                set_cell(x, y, 0);
            }
        }
    }
}

function update() {
    if (Input.justpressed(Key.SPACE)) {
        stepping = !stepping;
    }

    var mouse_x = Math.floor(Mouse.x / TILESIZE);
    var mouse_y = Math.floor(Mouse.y / TILESIZE);
    if (Mouse.leftclick() && in_bounds(mouse_x, mouse_y)) {
        var clicked_faction = world[mouse_x][mouse_y];
        for (x in 0...WORLD_SIZE) {
            for (y in 0...WORLD_SIZE) {
                if (world[x][y] == clicked_faction) {
                    set_cell(x, y, 0);
                }
            }
        }
    }

    if (Mouse.rightclick()) {
        set_cell(mouse_x, mouse_y, max_id);
        just_appeared_timer[max_id] = 3;
        max_id++;
    }

    if (stepping) {
        step_timer--;

        for (k in just_appeared_timer.keys()) {
            just_appeared_timer[k] = just_appeared_timer[k]--;

            if (just_appeared_timer[k] == 0) {
                just_appeared_timer.remove(k);
            }
        }
        
        if (step_timer <= 0) {
            step_timer = STEP_TIMER_MAX;

            Random.shuffle(positions);
            for (p in positions) {
                update_cell(p.x, p.y);
            }
        }
    }

    if (tutorial_timer > 0) {
        tutorial_timer--;
        Text.display(400, 0, 'Left click - pop\nRight click - spawn\nSpace - pause/resume', Col.GRAY);

        if (tutorial_timer <= 0) {
            Gfx.fillbox(400, 0, 400, 800, Col.BLACK);
        }
    }
}

}
