#version 300 es
// Rain on the glass, after BigWings' "Heartfelt": drops of every size sitting
// on the glass, and now and then one that runs down in fits and starts, taking
// in the drops it meets and leaving a faint wet line and a few beads behind.
// Every drop is a small lens, kept gentle so text stays readable. Only on the unfocused screens. Hyprland screen shader: needs
// debug:damage_tracking off for `time` to update.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

const float ASPECT = 16.0 / 9.0;
const float COLUMNS = 26.0;
uniform int wl_output;
out vec4 fragColor;

// From Weaselway's Hyprland patch: the focused screen, the one focused before it,
// and seconds since focus moved
uniform int focused_output;
uniform int previous_output;
uniform float focus_time;

const float REVEAL = 0.5;

// How much of the effect shows here: none on the focused screen, all on the
// others. For a moment after focus moves it closes in from the edges of
// the screen just left, and clears out from the middle of the one just reached.
float reach(vec2 st) {
    float p = clamp(focus_time / REVEAL, 0.0, 1.0);
    p = p * p * (3.0 - 2.0 * p);
    float d = length((st - 0.5) * vec2(ASPECT, 1.0)) / length(vec2(ASPECT, 1.0) * 0.5);
    // Clear inside radius r, the effect outside it
    float r;
    if (wl_output == focused_output) {
        r = focused_output == previous_output ? 1.0 : p;
    } else if (wl_output == previous_output) {
        r = 1.0 - p;
    } else {
        return 1.0;
    }
    // An uneven edge rather than a circle: lobes round it that shift as it moves,
    // a little ripple across the screen, and a new shape every switch. The seed
    // is the moment focus moved (time - focus_time), rounded to half seconds so
    // the two clocks' tiny drift between frames can't change it mid-switch.
    float seed = fract(sin(floor((time - focus_time) * 2.0) * 12.9898) * 43758.5453) * 100.0;
    float a = atan(st.y - 0.5, (st.x - 0.5) * ASPECT);
    float wobble = 0.09 * sin(a * 3.0 + seed * 1.7 + p * 1.5)
        + 0.06 * sin(a * 5.0 + seed * 4.1 - p * 2.0)
        + 0.035 * sin(a * 9.0 + seed * 2.3)
        + 0.025 * sin(st.x * 23.0 + seed) * sin(st.y * 19.0 - seed);
    d *= 1.0 + wobble;
    // A wide, soft edge, like a hair dryer on condensation: it thins out
    // gradually rather than stopping at a line. Scaled so r = 1 clears even the
    // corners at their widest lobe, soft edge and all.
    const float SOFT = 0.7;
    float edge = r * (1.22 + SOFT);
    return smoothstep(edge - SOFT, edge, d);
}

// Hyprland's v_texcoord.y grows down the screen, so it already means "down"
const float FALL = 1.0;

// hyprland.lua fills these in from the weather (these are the defaults): the
// rain in mm/h, the wind in km/h and the direction it blows from, and 1 in a
// thunderstorm
#define PRECIP 1.0
#define WIND 10.0
#define WIND_DIR 270.0
#define STORM 0.0
// How hard it's raining, 0 to 1: drizzle ~0.2, 1 mm/h ~0.4, 6 mm/h and up 1
const float HEAVY = clamp(sqrt(PRECIP / 6.0), 0.0, 1.0);
// The wind pushes the drops sideways as they run (positive is to the right)
// (1 at about 50 km/h, up to 2 in a 95 km/h gale)
const float SLANT = 0.3 * clamp((WIND - 5.0) / 45.0, 0.0, 2.0) * -sin(radians(WIND_DIR));

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
               mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

// A drop's water at q (its offset from the centre over its radius, y down):
// gravity sags the water to the bottom, so it's narrow on top and swells into
// a round belly below; sag 0 is round.
float bead(vec2 q, float sag, float top) {
    q.x /= 1.0 + sag * clamp(q.y, -1.0, 1.0);
    q.y *= q.y < 0.0 ? top : 1.0;
    return smoothstep(1.0, 0.2, length(q));
}

// The clinging drops that runners can take in sit at most one per cell of a
// CELLS-wide grid
const float CELLS = 28.0;
// When a running drop meets a clinging one it takes it in: their water adds
// up (a drop's weight goes as its radius cubed), so it grows by as much as it
// picked up, to at most RMAX so the lens stays gentle. The heavier it gets
// the faster it runs: WEIGHT_SPEED more speed for each time over its own
// starting weight it now carries, up to MAX_SPEEDUP. A clinging drop is
// pulled into a runner whose head comes within PULL above it.
const float WEIGHT_SPEED = 0.25;
const float MAX_SPEEDUP = 1.5;
const float RMAX = 0.008;
const float PULL = 0.02;

// Where grid cell id's clinging drops start in their appear-and-dry cycle
float clingStart(vec2 id) { return hash31(id.x * 107.45 + id.y * 3543.654).z; }
// Which of cell id's cycles is under way at time t
float clingCycle(vec2 id, float t) { return floor(t * 0.05 + clingStart(id)); }

// Grid cell id's clinging drop in a given cycle (each cycle a new one, in a
// new spot, or none): xy its centre, z its radius (0 when there's none), w its
// start less the cycle, so life() works as before and floor(t * 0.05 + w) is
// 0 exactly while this cycle is under way. Mostly small, now and then a big one.
vec4 cling(vec2 id, float cycle) {
    vec3 n = hash31(id.x * 107.45 + id.y * 3543.654 + mod(cycle, 997.0) * 71.17);
    if (fract(n.z * 13.0) < mix(0.8, 0.5, HEAVY)) return vec4(0.0);
    float size = mix(0.08, 0.2, pow(fract(n.z * 7.0), 1.6));
    return vec4((id + 0.5 + (n.xy - 0.5) * 0.75) / CELLS, size / CELLS, clingStart(id) - cycle);
}

// How far through its 20 second appear-and-dry cycle a clinging drop is
float life(vec4 d, float t) { return fract(t * 0.05 + d.w); }
// Whether a running drop can take it in then (it has to be there to take)
bool takeable(float l) { return l > 0.03 && l < 0.9; }

// Each column has up to two running drops, k = 0 and 1, with random numbers n
vec3 runnerHash(float column, int k) { return hash31(column * 13.7 + float(k) * 91.3); }
// Dry columns: most in drizzle, more in a downpour
bool wet(vec3 n) { return n.z >= mix(0.93, 0.72, HEAVY); }
// Each trip down runs from just above the screen to well below it, so its
// streak has time to mist over before the next trip starts
const float TRAVEL = 1.9;
float speedOf(vec3 n) { return mix(0.05, 0.1, n.x); }        // 5 to 10 seconds top to bottom
// Its whole part counts the trips down. It runs in fits and starts, as drops
// catch on the glass and let go: nearly stopping, then hurrying on.
float phaseOf(vec3 n, float t) {
    float w = mix(0.7, 1.4, n.z);
    return speedOf(n) * (t + 0.85 * sin(t * w + n.x * 40.0) / w) + n.y;
}
// How far down it would be by now, without speeding up
float progress(float phase) { return fract(phase) * TRAVEL - 0.15; }
// Roughly when trip pass got as far as progress b
float timeAt(vec3 n, float pass, float b) { return (pass + (b + 0.15) / TRAVEL - n.y) / speedOf(n); }

// Where a running drop's path crosses height y. The path wanders sideways as
// it comes down and leans with the wind; the streak follows it.
float pathX(vec3 n, float column, float y) {
    float path = (n.z - 0.5) * 0.5 + sin(y * 9.0 + n.x * 30.0) * 0.12
        + sin(y * 23.0 + n.y * 17.0) * 0.04;
    return (column + 0.5 + path) / COLUMNS * ASPECT + SLANT * y;
}

// How big a drop carrying this much water is
float radiusOf(float weight) { return min(pow(weight, 1.0 / 3.0), RMAX); }

struct Run {
    float head;   // how far down it is
    float r;      // how big it is
    float took;   // when it took in the target drop (-1e9: it didn't)
};

// Follows a running drop down on one trip (pass), taking in the clinging
// drops it meets, until it has got as far as progress b (counted without
// speeding up) or past the target cell's row.
Run walk(vec3 n, float column, float pass, float b, vec2 target) {
    // Since its last merge it has moved m times as fast: at progress ab it was at ay
    float ay = -0.15, ab = -0.15, m = 1.0;
    float r0 = mix(0.004, 0.0065, n.y);
    float weight = r0 * r0 * r0;
    float took = -1e9;
    for (int j = 0; j < int(CELLS); j++) {
        float fj = float(j);
        // A cell's drop sits between 0.125 and 0.875 of the way down it
        if (ay + m * (b - ab) < (fj + 0.125) / CELLS || fj > target.y) break;
        float yc = (fj + 0.5) / CELLS;
        float ix = floor(pathX(n, column, yc) * CELLS);
        // Roughly when it gets to this row, to know which cycle's drops are here
        float tc = timeAt(n, pass, ab + (yc - ay) / m);
        vec2 c0 = vec2(ix - 1.0, fj), c1 = vec2(ix, fj), c2 = vec2(ix + 1.0, fj);
        vec4 d0 = cling(c0, clingCycle(c0, tc)), d1 = cling(c1, clingCycle(c1, tc)),
             d2 = cling(c2, clingCycle(c2, tc));
        float i0 = ix - 1.0, i1 = ix, i2 = ix + 1.0;
        if (d0.z == 0.0) d0.y = 1e9;
        if (d1.z == 0.0) d1.y = 1e9;
        if (d2.z == 0.0) d2.y = 1e9;
        // Meet them in order, top first
        vec4 dt; float it;
        if (d0.y > d1.y) { dt = d0; d0 = d1; d1 = dt; it = i0; i0 = i1; i1 = it; }
        if (d1.y > d2.y) { dt = d1; d1 = d2; d2 = dt; it = i1; i1 = i2; i2 = it; }
        if (d0.y > d1.y) { dt = d0; d0 = d1; d1 = dt; it = i0; i0 = i1; i1 = it; }
        for (int q = 0; q < 3; q++) {
            vec4 d = q == 0 ? d0 : q == 1 ? d1 : d2;
            float id = q == 0 ? i0 : q == 1 ? i1 : i2;
            if (d.y > ay + m * (b - ab)) break;                    // not there yet
            if (abs(d.x - pathX(n, column, d.y)) > radiusOf(weight) + d.z) continue;   // passes by
            float bd = ab + (d.y - ay) / m;
            float td = timeAt(n, pass, bd);                        // when it got there
            // Only if that same drop is still there when it actually arrives
            if (floor(td * 0.05 + d.w) != 0.0 || !takeable(life(d, td))) continue;
            ab = bd;
            ay = d.y;
            weight += d.z * d.z * d.z;
            m = min(1.0 + WEIGHT_SPEED * (weight / (r0 * r0 * r0) - 1.0), MAX_SPEEDUP);
            if (vec2(id, fj) == target) took = td;
        }
    }
    return Run(ay + m * (b - ab), radiusOf(weight), took);
}

// Water from a drop of radius r: x how much, y how far it lifts what's behind
// it, in proportion to the drop, so the smallest don't show things from
// beyond their edges
vec2 lens(float water, float r) { return vec2(water, water * r * 0.55); }
vec2 wettest(vec2 a, vec2 b) { return a.x >= b.x ? a : b; }

// The drops running down, at uv (x across 0 to ASPECT, y down from 0 at the
// top). xy: their water (see lens()); z: how wet the lines they left are.
vec3 running(vec2 uv, float t) {
    float cx = (uv.x - SLANT * uv.y) / ASPECT * COLUMNS;
    // This column, and the neighbour on the nearer side (a big drop can spill over)
    float home = floor(cx);
    float side = fract(cx) < 0.5 ? -1.0 : 1.0;
    vec2 water = vec2(0.0);
    float clearing = 0.0;
    for (int i = 0; i < 2; i++) {
        float column = home + float(i) * side;
        for (int k = 0; k < 2; k++) {
            vec3 n = runnerHash(column, k);
            if (!wet(n)) continue;
            // Skip the walk where this drop can't reach: too far across, or
            // below its head however much it has sped up
            float dx = uv.x - pathX(n, column, uv.y);
            if (abs(dx) > RMAX * 1.3) continue;
            float ph = phaseOf(n, t);
            float b = progress(ph);
            if (uv.y > -0.15 + MAX_SPEEDUP * (b + 0.15) + RMAX * 2.0) continue;
            float pass = floor(ph);
            Run run = walk(n, column, pass, b, vec2(0.0, 1e9));
            float r = run.r;
            vec2 head = vec2(pathX(n, column, run.head), run.head);
            // The drop: a teardrop, its water piled into the front and drawn out behind
            water = wettest(water, lens(bead((uv - head) / r, 0.3, 0.55), r));
            float dy = uv.y - run.head;
            // The wet line where it passed: much narrower than the drop, ragged,
            // drying off the longer ago that was, and all of it once the drop
            // has gone off the bottom
            float passed = max(-dy, 0.0) / (speedOf(n) * TRAVEL);
            float width = r * 0.3 * (0.6 + 0.8 * noise(vec2(uv.y * 60.0, column * 3.0 + float(k))));
            float streak = step(dy, -r) * smoothstep(width, width * 0.3, abs(dx))
                * exp(-passed / 2.5) * smoothstep(TRAVEL - 0.15, 1.1, b);
            // And here and there a little bead it left behind, stuck to the glass
            for (int j = -1; j <= 1; j++) {
                float row = floor(uv.y / 0.012) + float(j);
                vec3 h = hash31(row * 7.31 + column * 131.7 + float(k) * 17.3 + mod(pass, 97.0) * 3.1);
                if (h.z > 0.45) continue;
                float y = (row + 0.5 + (h.y - 0.5) * 0.6) * 0.012;
                if (y > run.head - r) continue;
                float rb = r * mix(0.2, 0.45, h.x) * smoothstep(TRAVEL - 0.15, 1.2, b);
                vec2 c = vec2(pathX(n, column, y) + (h.y - 0.5) * r * 0.5, y);
                water = wettest(water, lens(bead((uv - c) / max(rb, 1e-4), 0.2, 0.9), rb));
            }
            clearing = max(clearing, streak);
        }
    }
    return vec3(water, clearing);
}

// The drops sitting on the glass: their water (see lens()). Runners take them
// in. clearing: how wet the runners' lines are here; they take the finest drops with them.
vec2 clinging(vec2 uv, float t, float clearing) {
    vec2 here = floor(uv * CELLS);
    vec2 water = vec2(0.0);
    for (int cy = -1; cy <= 1; cy++) {
        for (int cx = -1; cx <= 1; cx++) {
            vec2 id = here + vec2(float(cx), float(cy));
            vec4 d = cling(id, clingCycle(id, t));
            // Far enough that even pulled into a runner it can't cover this pixel
            if (d.z == 0.0 || distance(uv, d.xy) > d.z * 1.4 + 0.03) continue;
            float l = life(d, t);
            // It lands all at once, and dries up slowly, shrinking away
            float grown = smoothstep(0.0, 0.03, l) * smoothstep(1.0, 0.7, l);
            if (grown <= 0.0) continue;
            vec2 centre = d.xy;
            bool gone = false;
            // Running drops that pass near it, on this trip or the two before
            // (enough to cover its 20 second cycle)
            float home = floor((d.x - SLANT * d.y) / ASPECT * COLUMNS);
            for (int ci = -1; ci <= 1 && !gone; ci++) {
                float column = home + float(ci);
                for (int k = 0; k < 2 && !gone; k++) {
                    vec3 n = runnerHash(column, k);
                    if (!wet(n)) continue;
                    if (abs(d.x - pathX(n, column, d.y)) > RMAX + d.z) continue;
                    float ph = phaseOf(n, t);
                    for (int p = 0; p < 3; p++) {
                        Run run = walk(n, column, floor(ph) - float(p),
                                       p == 0 ? progress(ph) : TRAVEL - 0.15, id);
                        // Taken in already, during this cycle of the drop's
                        if (run.took > -1e8 && floor(run.took * 0.05 + d.w) == floor(t * 0.05 + d.w)) {
                            gone = true;
                            break;
                        }
                        // Coming down on it, close enough to take it: drawn up into the head
                        float gap = d.y - run.head;
                        if (p == 0 && gap > 0.0 && gap < PULL && takeable(l)
                                && abs(d.x - pathX(n, column, d.y)) <= run.r + d.z) {
                            float s = smoothstep(PULL, 0.0, gap);
                            centre = mix(d.xy, vec2(pathX(n, column, run.head), run.head), s * s);
                        }
                    }
                }
            }
            if (gone) continue;
            // The bigger it is, the more its water sags
            float r = d.z * sqrt(grown);
            float sag = mix(0.05, 0.3, smoothstep(0.003, 0.007, d.z));
            water = wettest(water, lens(bead((uv - centre) / r, sag, mix(1.0, 0.8, sag * 3.0)), r));
        }
    }
    // The finest: condensation, too small to run, a few to a cell of a finer
    // grid, each landing and drying in its own time
    vec2 fine = uv * 70.0;
    vec2 id = floor(fine);
    vec3 n = hash31(id.x * 41.3 + id.y * 2917.1);
    float l = fract(t * 0.03 + n.z);
    vec3 m = hash31(id.x * 41.3 + id.y * 2917.1 + floor(t * 0.03 + n.z) * 13.7);
    if (m.z < mix(0.2, 0.35, HEAVY)) {
        float rf = mix(0.07, 0.18, m.x * m.x) * smoothstep(0.0, 0.05, l) * smoothstep(1.0, 0.6, l);
        vec2 q = (fract(fine) - 0.5 - (m.xy - 0.5) * 0.5) / max(rf, 1e-4);
        water = wettest(water, lens(bead(q, 0.1, 1.0) * 0.8 * (1.0 - clearing), rf / 70.0));
    }
    return water;
}

void main() {
    vec2 st = v_texcoord;
    vec3 clear = texture(tex, st).rgb;
    float shown = reach(st);
    if (shown <= 0.0) {
        fragColor = vec4(clear, 1.0);
        return;
    }

    vec2 uv = vec2(st.x * ASPECT, FALL < 0.0 ? 1.0 - st.y : st.y);
    float t = time;

    vec3 run = running(uv, t);
    vec2 water = wettest(run.xy, clinging(uv, t, run.z));

    vec3 col = clear;

    // The wet lines: a thin film, a touch brighter, bending things a hair
    if (run.z > 0.0) {
        vec3 film = texture(tex, st + vec2(0.0, -0.0012 * FALL)).rgb + 0.03;
        col = mix(col, film, run.z * 0.35);
    }

    // The drops: small lenses that lift what's behind them. Each gets a clean
    // edge, a darker rim where its curve bends the light away, and a brighter
    // middle, so it reads against a plain screen.
    if (water.x > 0.0) {
        float cover = smoothstep(0.0, 0.18, water.x);
        vec3 seen = texture(tex, st + vec2(0.0, -water.y * FALL)).rgb;
        seen *= 1.0 - 0.3 * cover * (1.0 - smoothstep(0.1, 0.55, water.x));
        seen += 0.0175 + 0.03 * smoothstep(0.55, 1.0, water.x);
        col = mix(col, seen, cover);
    }

    // In a thunderstorm, now and then a faint double flash of lightning
    if (STORM > 0.5) {
        float period = 27.0;
        float cycle = floor(t / period);
        float phase = fract(t / period) * period;
        vec3 n = hash31(cycle * 3.7 + 1.3);
        float at = n.x * (period - 2.0);
        float flash = n.y < 0.6 ? max(exp(-pow((phase - at) / 0.05, 2.0)),
                                      0.6 * exp(-pow((phase - at - 0.25) / 0.07, 2.0))) : 0.0;
        col.rgb = mix(col.rgb, vec3(0.92, 0.94, 1.0), flash * 0.12);
    }

    fragColor = vec4(mix(clear, col.rgb, shown), 1.0);
}
