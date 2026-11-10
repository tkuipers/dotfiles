#version 300 es
// Snow on the glass: flakes drifting down the window, some catching for a moment
// before melting or falling on, and a soft bank of snow settled along the
// bottom edge. Kept light so text stays readable. Only on the unfocused screens.
// Hyprland screen shader: needs debug:damage_tracking off for `time` to update.
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

// true snows on both screens, focused or not (for testing)
const bool BOTH_SCREENS = false;
const vec3 SNOW = vec3(0.95, 0.97, 1.0);

// hyprland.lua fills these in from the weather (these are the defaults): the
// snowfall in cm/h, the wind in km/h and the direction it blows from
#define SNOWFALL 0.5
#define WIND 10.0
#define WIND_DIR 270.0
// How hard it's snowing, 0 to 1: light ~0.2, 0.5 cm/h ~0.45, 2.5 cm/h and up 1
const float HEAVY = clamp(sqrt(SNOWFALL / 2.5), 0.0, 1.0);
// How windy: 1 at about 45 km/h, up to 2 in a 90 km/h gale; and which way it
// carries the flakes (positive is right)
const float WINDY = clamp((WIND - 5.0) / 40.0, 0.0, 2.1);
const float DRIFT = 0.35 * WINDY * -sin(radians(WIND_DIR));

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

vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

// The falling flakes, in columns: how much flake covers this point. Now and
// then one catches on the glass for a moment, then either melts away where it
// stopped or lets go and keeps falling (decided afresh on every pass).
float falling(vec2 st, float t, float cols, float seed) {
    // The wind carries the flakes sideways as they fall
    st.x -= DRIFT * st.y;
    float cx = st.x * cols;
    float column = floor(cx);
    float within = fract(cx) - 0.5;
    float h = 0.0;
    for (int k = 0; k < 3; k++) {
        vec3 n = hash31(column * 13.7 + float(k) * 91.3 + seed);
        if (n.z < mix(0.82, 0.3, HEAVY)) continue;         // more columns snow the heavier it falls
        float rate = mix(0.035, 0.05, n.x);                 // 20 to 28 seconds down the screen
        float cycle = t * rate + n.y + float(k) / 3.0;
        float u = fract(cycle);
        vec3 m = hash31(column * 7.1 + float(k) * 3.3 + seed + floor(cycle));
        bool sticks = m.x < 0.15;
        bool melts = m.y < 0.5;
        // Share of the pass spent stuck: longer for the ones that melt, so they
        // shrink away slowly
        float d = sticks ? (melts ? mix(0.15, 0.25, m.z) : mix(0.08, 0.15, m.z)) : 0.0;
        float at = mix(0.15, 0.85, fract(m.z * 7.0));      // where it catches
        float f = 1.0 - d;
        float y;
        float stuck = 0.0;
        float shown = 1.0;
        if (u < at * f) {
            y = u / f;
        } else if (u < at * f + d) {
            y = at;
            stuck = (u - at * f) / d;
        } else {
            y = (u - d) / f;
            if (sticks && melts) shown = 0.0;
        }
        y = y * 1.1 - 0.05;                                 // enter above, leave below
        // Drifts side to side as it falls (by height, so it holds still when stuck)
        float sway = (sin(y * 7.0 + n.x * 30.0) * 0.2 + sin(y * 17.0 + n.y * 11.0) * 0.06) * (1.0 + 0.35 * min(WINDY, 1.0));
        float r = mix(0.005, 0.007, n.y);
        // Melting: it starts shrinking the moment it catches, down to nothing
        if (sticks && melts) r *= 1.0 - stuck;
        vec2 dv = vec2((within - sway) / cols * ASPECT, st.y - y);
        // Its shape: a soft, slightly ragged flake, between a dot and a crystal.
        // The edge bulges out a little in six places, unevenly, and the flake
        // turns slowly as it falls (not while stuck).
        if (length(dv) > r * 1.5) continue;
        // Tumbling: it turns end over end about an axis across it (each flake's
        // axis tilted its own way), so it narrows to an edge and widens again
        // as it falls. Holds still while stuck, since it goes by height.
        float tilt = n.z * 3.1416;
        mat2 toAxis = mat2(cos(tilt), -sin(tilt), sin(tilt), cos(tilt));
        float face = cos(y * mix(4.0, 32.0, fract(n.x * 13.7)) + n.y * 6.2832);
        vec2 local = toAxis * dv;
        local.x /= max(abs(face), 0.18);
        dv = local * toAxis;
        float len = length(dv);
        float ang = atan(dv.y, dv.x) + y * (n.x - 0.5) * 12.0;
        float edge = r * (0.8 + 0.22 * pow(abs(cos(ang * 3.0)), 3.0)
            + 0.12 * sin(ang * 2.0 + n.y * 20.0) + 0.08 * sin(ang * 5.0 + n.x * 9.0));
        float flake = smoothstep(edge, edge * 0.35, len);
        // A brighter heart, a fainter edge
        flake *= mix(0.65, 1.0, smoothstep(edge * 0.6, 0.0, len));
        // Faces catch more light than edges
        flake *= mix(0.7, 1.0, abs(face));
        h = max(h, flake * shown);
    }
    return h;
}

// Frosted: a soft blur of what's behind, from a ring of samples
vec3 frosted(vec2 at, float radius) {
    vec2 px = radius / vec2(textureSize(tex, 0));
    vec3 sum = texture(tex, at).rgb;
    for (int i = 0; i < 8; i++) {
        float a = float(i) * 0.7854;
        sum += texture(tex, at + vec2(cos(a), sin(a)) * px).rgb;
    }
    return sum / 9.0;
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
    vec3 col = clear;

    // The bank along the bottom: a low, even line of snow with a lumpy top
    // where clumps sit
    // A little taller in heavy snow
    float top = mix(0.012, 0.028, HEAVY) + 0.012 * fbm(vec2(uv.x * 6.0, 2.0))
        + 0.005 * noise(vec2(uv.x * 45.0, 7.0));
    float bank = smoothstep(top + 0.003, top - 0.003, fromBottom);
    if (bank > 0.0) {
        float depth = clamp((top - fromBottom) / max(top, 0.001), 0.0, 1.0);  // 0 at its top
        float grain = fbm(uv * 180.0);
        // Bright along the crest, a cool shade deeper down
        vec3 settled = mix(SNOW, vec3(0.78, 0.84, 0.95), smoothstep(0.05, 0.9, depth) * 0.45);
        settled *= mix(0.95, 1.03, grain);
        settled += smoothstep(0.25, 0.0, depth) * 0.05;
        // A few sparkles
        float sparkle = step(0.997, hash12(floor(st * vec2(textureSize(tex, 0)) / 2.0)))
            * pow(max(0.0, sin(t * 2.0 + hash12(floor(st * 400.0)) * 60.0)), 8.0);
        settled += sparkle * 0.5;
        // Translucent right at the crest, nearly solid below
        float body = mix(0.55, 0.92, smoothstep(0.0, 0.35, depth));
        col = mix(col, mix(frosted(st, 3.0), settled, body), bank);
    }

    // Falling flakes: two sets of columns so they don't line up
    float a = falling(st, t, 36.0, 1.0);
    float b = falling(st, t, 31.0, 7.0);
    col = mix(col, SNOW, max(a, b) * 0.6);

    fragColor = vec4(mix(clear, col, shown), 1.0);
}
