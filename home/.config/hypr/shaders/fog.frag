#version 300 es
// Condensation on the glass, for cloudy days: a light fog over the pane, thicker
// towards the top, breathing thicker and thinner. Now and then a
// drop grows heavy and runs down, wiping a clear streak through it that
// slowly mists back over. Kept light so text stays readable. Only on the
// unfocused screens. Hyprland screen shader: needs debug:damage_tracking off for
// `time` to update.
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
uniform float time;

const float ASPECT = 16.0 / 9.0;
uniform int wl_output;
// From Weaselway's Hyprland patch: the focused screen, the one focused before it,
// and seconds since focus moved
uniform int focused_output;
uniform int previous_output;
uniform float focus_time;
out vec4 fragColor;

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

// true fogs both screens, focused or not (for testing)
const bool BOTH_SCREENS = false;

// hyprland.lua fills these in from the weather (these are the defaults): the
// humidity in %, and 1 when it's actual fog outside
#define HUMIDITY 85.0
#define FOG 0.0
// How damp, 0 to 1, from fairly dry air to saturated
const float DAMP = smoothstep(55.0, 100.0, HUMIDITY);
// The fog's thickness: thinner in drier air, heavier when damp, heaviest in fog
const float THICKNESS = mix(0.72, 1.12, DAMP) * (FOG > 0.5 ? 1.3 : 1.0);
const vec3 MIST = vec3(0.9, 0.93, 0.97);
const float COLUMNS = 30.0;

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

// How thick the fog is at uv (y down the screen) at time t: thicker towards the
// top, like cloud in the sky, in patches that drift slowly and breathe, thickening and thinning,
// each part of the screen in its own time. 1.0 is the old even fog; it ranges
// from well below that up to a third more.
// The patches alone, without the thickening towards the top
float patchAt(vec2 uv, float t) {
    float patches = fbm(uv * 2.5 + vec2(t * 0.01, t * 0.006) + 4.0);
    float breathe = 0.5 + 0.5 * sin(t * 0.15 + fbm(uv * 1.5 + 11.0) * 6.2832);
    return mix(0.35, 1.33, 0.5 * patches + 0.5 * breathe);
}
float fogAt(vec2 uv, float t) {
    return (0.5 + 1.0 * smoothstep(0.8, 0.0, uv.y)) * patchAt(uv, t) * THICKNESS;
}

// The runs: drops that let go at a random height and slide down. Returns how
// clear the glass is here (x: 1 = freshly wiped) and how much running drop
// covers it (y).
vec2 runs(vec2 uv, float t) {
    float cx = uv.x / ASPECT * COLUMNS;
    float column = floor(cx);
    float within = fract(cx) - 0.5;
    vec2 result = vec2(0.0);
    for (int k = 0; k < 1; k++) {
        vec3 n = hash31(column * 13.7 + float(k) * 91.3);
        float period = mix(40.0, 70.0, n.x);              // one run per column every minute or so
        float cycle = t / period + n.y + float(k) * 0.5;
        float u = fract(cycle);
        vec3 m = hash31(column * 127.1 + float(k) * 57.3 + floor(cycle) * 311.7);
        float start = mix(0.05, 0.6, m.y);                // where it lets go
        float speed = mix(0.04, 0.09, m.z);               // slow, heavy drops
        float age = u * period;                            // seconds since it began to gather
        // Rare, one or two on a screen at a time, and far likelier where the fog
        // was thick when it let go
        float thick = patchAt(vec2((column + 0.5) / COLUMNS * ASPECT, start), t - age);
        // (and more often the damper the air)
        if (fract(m.x * 31.7) > 0.3 * mix(0.4, 1.5, DAMP) * smoothstep(0.6, 1.15, thick)) continue;
        // First it gathers: a bead swells in place for a few seconds. Then it lets go, slowly at first and gathering
        // speed, catching for a moment now and then on its way down.
        float gather = mix(4.0, 9.0, fract(m.z * 13.1));
        float grown = clamp(age / gather, 0.0, 1.0);
        float slid = max(age - gather, 0.0);               // seconds since it let go
        float travelled = slid * slid / (slid + 3.0);      // eases off the mark
        travelled += 0.6 * sin(slid * 0.9 + m.x * 20.0) / 0.9 * smoothstep(0.0, 3.0, slid) * 0.4;
        float head = start + max(travelled, 0.0) * speed;
        // The path wanders sideways; the streak follows it
        float path = (m.z - 0.5) * 0.4 + sin(uv.y * 11.0 + m.x * 30.0) * 0.1
            + sin(uv.y * 29.0 + m.y * 17.0) * 0.035;
        float dx = (within - path) / COLUMNS * ASPECT;
        float dy = uv.y - head;
        // The drop: swelling while it gathers, fattest as it lets go, thinning as
        // it leaves water behind; round while it sits, longer once it runs
        float size = mix(1.0 / 3.0, 1.0, fract(m.x * 7.3));
        float r = mix(0.0165, 0.0105, clamp(slid * speed / 0.5, 0.0, 1.0)) * size * sqrt(grown);
        float stretch = mix(1.0, 0.7, smoothstep(0.0, 2.0, slid));
        float drop = smoothstep(r, r * 0.2, length(vec2(dx, dy * stretch)));
        // The streak behind it: clear where it passed, misting back over
        // the longer ago that was
        float passed = (head - uv.y) / speed;              // seconds since the drop was here
        float width = r * 0.75 * (0.8 + 0.4 * noise(vec2(uv.y * 60.0, column)));
        // It starts softly, with a ragged top, where the drop gathered
        float top = start - 0.012 * noise(vec2(uv.x * 400.0, column));
        float streak = smoothstep(top - 0.006, top + 0.02, uv.y) * step(0.0, passed) * step(0.001, slid)
            * smoothstep(width, width * 0.4, abs(dx)) * exp(-passed / 18.0);
        result = max(result, vec2(streak, drop));
    }
    return result;
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
    float t = time;

    float fog = fogAt(uv, t);

    vec2 run = runs(uv, t);
    fog *= 1.0 - run.x;

    // A light blur and a whitening, both gentle enough to read through
    vec2 px = 1.6 / vec2(textureSize(tex, 0));
    vec3 soft = (clear
        + texture(tex, st + vec2(px.x, 0.0)).rgb + texture(tex, st - vec2(px.x, 0.0)).rgb
        + texture(tex, st + vec2(0.0, px.y)).rgb + texture(tex, st - vec2(0.0, px.y)).rgb) / 5.0;
    vec3 col = mix(clear, soft, min(fog, 1.0));
    col = mix(col, MIST, 0.16 * fog);

    // The running drops themselves: small clear lenses
    if (run.y > 0.0) {
        vec3 lens = texture(tex, st + vec2(0.0, -0.009) * run.y).rgb + 0.05;
        col = mix(col, lens, run.y);
    }

    fragColor = vec4(mix(clear, col, shown), 1.0);
}
