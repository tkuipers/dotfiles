#version 300 es
// Frost on the glass, for the deep cold: a crust of clear ice crystals along the bottom that
// creeps a little up the sides, frozen beads above it thinning out, and a light
// haze that's gone a third of the way up. The crust slowly grows and recedes and
// its crystals glint. Only on the unfocused screens, like the rain.
// Hyprland screen shader: needs debug:damage_tracking off for `time` to update.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

const float ASPECT = 16.0 / 9.0;
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

// true frosts both screens, focused or not (for testing)
const bool BOTH_SCREENS = false;
const vec3 ICE = vec3(0.86, 0.93, 1.0);

// hyprland.lua fills this in from the weather (this is the default): °C
#define TEMP -20.0
// How cold, 0 to 1, from -10 to -30: a thin rim at the edge of frost, crust up
// the sides by -30, and on up most of the sides by -60 (the look tuned at -20 is the middle)
const float COLD = smoothstep(-10.0, -30.0, TEMP);
// Deep cold, 0 to 1 from -30 to -60: the crust keeps climbing, the sides most
const float DEEP = clamp((-30.0 - TEMP) / 30.0, 0.0, 1.0);

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(0.1031, 0.1030, 0.0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash12(i), hash12(i + vec2(1.0, 0.0)), u.x),
               mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = p * 2.03 + 17.1;
        a *= 0.5;
    }
    return v;
}

// Crystal facets: distance to the nearest and second nearest seed, and the
// nearest seed's own random value
vec3 facets(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float d1 = 8.0;
    float d2 = 8.0;
    float id = 0.0;
    for (int y = -1; y <= 1; y++) {
        for (int x = -1; x <= 1; x++) {
            vec2 g = vec2(float(x), float(y));
            vec2 o = hash22(i + g);
            float d = length(g + o - f);
            if (d < d1) {
                d2 = d1;
                d1 = d;
                id = hash12(i + g + 7.7);
            } else if (d < d2) {
                d2 = d;
            }
        }
    }
    return vec3(d1, d2, id);
}

// Frosted: a soft blur of what's behind, from a ring of samples
vec3 frosted(vec2 at, float radius) {
    vec2 px = radius / vec2(textureSize(tex, 0));
    vec3 sum = texture(tex, at).rgb;
    for (int i = 0; i < 12; i++) {
        float a = float(i) * 0.5236;
        float r = (i % 2 == 0) ? 1.0 : 0.55;
        sum += texture(tex, at + vec2(cos(a), sin(a)) * px * r).rgb;
    }
    return sum / 13.0;
}

void main() {
    vec2 st = v_texcoord;
    vec3 clear = texture(tex, st).rgb;
    float shown = BOTH_SCREENS ? 1.0 : reach(st);
    if (shown <= 0.0) {
        fragColor = vec4(clear, 1.0);
        return;
    }

    vec2 uv = vec2(st.x * ASPECT, st.y);
    float fromBottom = 1.0 - st.y;
    float t = time;

    // The crust's top edge: ragged, slowly growing and receding
    float creep = 0.012 * sin(t * 0.09) + 0.006 * sin(t * 0.23 + 1.3);
    float edge = mix(0.03, 0.07, COLD) + 0.05 * DEEP + 0.035 * fbm(vec2(uv.x * 5.0, t * 0.015)) + 0.012 * noise(vec2(uv.x * 40.0, 3.0)) + creep;
    // Up the sides, thicker towards the bottom corners. Each side has its own
    // shape and thickness, so they don't mirror each other.
    bool left = uv.x < ASPECT * 0.5;
    float fromSide = left ? uv.x : ASPECT - uv.x;
    float sideSeed = left ? 9.0 : 63.0;
    float sideAmount = (left ? 1.0 : 0.7) * mix(0.4, 1.6, COLD) * (1.0 + 0.8 * DEEP);
    // Only the bottom third, thick in the corners and tapering to nothing
    float sideHeight = (left ? 0.667 : 0.72) + mix(0.15, -0.15, COLD) - 0.3 * DEEP;
    float sideEdge = sideAmount * 0.09 * smoothstep(sideHeight, 1.0, st.y)
        * (0.45 + 1.0 * fbm(vec2(st.y * (left ? 6.0 : 8.5), sideSeed + t * 0.01)));
    float ice = max(smoothstep(edge + 0.008, edge - 0.004, fromBottom),
                    smoothstep(sideEdge + 0.008, sideEdge - 0.003, fromSide));
    // Not solid: the ice gathers in patches, continuous only in a thin strip at
    // the very bottom, and thins out towards its edge
    float patches = smoothstep(0.38, 0.68, fbm(uv * vec2(11.0, 18.0) + vec2(0.0, t * 0.004)));
    float density = mix(patches, 1.0, smoothstep(edge * 0.35, 0.0, fromBottom));
    ice *= density;
    float rim = density * max(smoothstep(0.012, 0.0, abs(fromBottom - edge)) * step(fromBottom, edge + 0.012),
                    smoothstep(0.008, 0.0, abs(fromSide - sideEdge)) * step(fromSide, sideEdge + 0.008));

    // Above the crust: frozen beads, densest near the ice, gone by 0.15
    float above = fromBottom - edge;
    float beadZone = smoothstep(mix(0.1, 0.2, COLD) + 0.1 * DEEP, 0.0, above) * step(0.0, above);
    // Two scattered layers at unrelated scales, each row shifted at random, so
    // the beads don't line up
    float bead = 0.0;
    vec2 slope = vec2(0.0);
    vec2 within = vec2(0.0);
    vec2 offset = vec2(0.0);
    for (int layer = 0; layer < 2; layer++) {
        float scale = layer == 0 ? 41.0 : 67.0;
        vec2 cells = uv * scale + float(layer) * vec2(13.7, 5.3);
        cells.x += hash12(vec2(floor(cells.y), float(layer) * 3.0)) * 7.0;
        vec2 cell = floor(cells);
        vec2 w = fract(cells) - 0.5;
        vec2 seed = hash22(cell + 3.1 + float(layer) * 19.0);
        float chance = beadZone * beadZone * (layer == 0 ? 0.22 : 0.3);
        float present = step(hash12(cell + 11.0 + float(layer) * 41.0), chance);
        float radius = mix(0.06, 0.32, seed.x * seed.x);
        vec2 o = (seed - 0.5) * (0.9 - radius * 2.0);
        float d = length(w - o);
        float b = present * smoothstep(radius, radius * 0.4, d);
        if (b > bead) {
            bead = b;
            slope = present * (w - o) * smoothstep(radius, 0.0, d);
            within = w;
            offset = o;
        }
    }

    // The haze over the bottom third, thicker towards the ice
    float haze = smoothstep(0.3, 0.0, above) * step(0.0, above) * (mix(0.15, 0.29, COLD) + 0.04 * DEEP);

    if (ice + rim + bead + haze <= 0.001) {
        fragColor = vec4(clear, 1.0);
        return;
    }

    vec3 col = clear;

    // Haze: a little blur and a little white
    if (haze > 0.0) {
        vec3 soft = frosted(st, 3.0);
        col = mix(col, mix(soft, ICE, 0.12), haze);
    }

    // Beads: tiny frozen lenses with a cold glint on top
    if (bead > 0.0) {
        vec3 through = texture(tex, st - slope * 0.004).rgb;
        through = mix(through, ICE, 0.18);
        through += smoothstep(0.1, -0.25, within.y - offset.y) * 0.12 * bead;
        col = mix(col, through, bead);
    }

    // The crust: clear ice in crystals. Each facet bends what's behind it its own
    // way, like cut glass, with a faint cold tint; thin bright lines trace the
    // facets' edges.
    if (ice > 0.0) {
        vec3 f = facets(uv * 90.0);
        float boundary = 1.0 - smoothstep(0.0, 0.05, f.y - f.x);
        vec2 tilt = (vec2(fract(f.z * 13.1), fract(f.z * 7.3)) - 0.5) * 0.006;
        vec3 behind = mix(texture(tex, st + tilt).rgb, frosted(st + tilt, 2.5), 0.5);
        float grain = fbm(uv * 260.0);
        vec3 crust = mix(behind, ICE, 0.12 + 0.08 * grain) * mix(0.96, 1.05, f.z);
        crust = mix(crust, vec3(1.0), boundary * 0.22);
        // Glints: a few facets catch the light now and then
        float glint = pow(max(0.0, sin(t * (0.6 + f.z * 1.4) + f.z * 40.0)), 24.0)
            * step(0.82, f.z) * smoothstep(0.25, 0.0, f.x);
        crust += glint * 0.45;
        col = mix(col, crust, ice * 0.7);
    }

    // The crust's edge: clear, refracting ice catching the light
    if (rim > 0.0) {
        vec3 edgeIce = texture(tex, st + vec2(0.0, 0.004) * rim).rgb;
        edgeIce = mix(edgeIce, vec3(1.0), 0.15);
        col = mix(col, edgeIce, rim * 0.45);
    }

    fragColor = vec4(mix(clear, col, shown), 1.0);
}
