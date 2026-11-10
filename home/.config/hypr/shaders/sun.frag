#version 300 es
// Sun on the glass, for clear days: warm light falling in from above, from the
// left in the morning, overhead at midday and the right in the evening, breathing
// slowly as if thin cloud were passing. A few faint flare ghosts along the line
// away from it, and dust and smudges on the glass that show only where the light
// falls, a speck glinting now and then. Dust motes floating
// in the light, a few soft sunbeams coming and going, colour that follows the time of day. Kept light so text stays readable. Only
// on the unfocused screens. Hyprland screen shader: needs debug:damage_tracking
// off for `time` to update.
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

// hyprland.lua fills this in when it loads the shader (and again each hour):
// how far through the day it is, 0 at 6:00 to 1 at 18:00
#define DAY_FRACTION 0.5
// and how cloudy it is, 0 to 100: a clear sky is all glow and no beams; as
// cloud comes in the glow dims and the beams grow, more and stronger
#define CLOUD_COVER 0.0
// and the wind in km/h, and the direction it blows from: the cloud drifts
// faster on a windy day, and its way
#define WIND 10.0
#define WIND_DIR 270.0
const float GUSTS = 0.5 + 2.0 * clamp(WIND / 40.0, 0.0, 2.25);   // up to 5x in a 90 km/h gale
const float WIND_WAY = -sin(radians(WIND_DIR)) < 0.0 ? -1.0 : 1.0;

const float REVEAL = 0.5;

// Where the sun is, in uv (x 0 to ASPECT, y down): just above the top edge,
// travelling left to right through the day and highest at midday
vec2 sunAt() {
    float day = clamp(DAY_FRACTION, 0.0, 1.0);
    return vec2(mix(-0.15, ASPECT + 0.15, day), -0.12 - 0.12 * sin(day * 3.1416));
}

// How much of the effect shows here: none on the focused screen, all on the
// others. Unlike the other weather, the light pours out of the sun on the screen
// just left, and draws back into it on the one just reached.
float reach(vec2 st) {
    float p = clamp(focus_time / REVEAL, 0.0, 1.0);
    p = p * p * (3.0 - 2.0 * p);
    vec2 uv = vec2(st.x * ASPECT, st.y);
    vec2 sun = sunAt();
    // Distance from the sun, 1 at the furthest corner
    float far = max(max(length(vec2(0.0, 1.0) - sun), length(vec2(ASPECT, 1.0) - sun)),
                    max(length(vec2(0.0) - sun), length(vec2(ASPECT, 0.0) - sun)));
    float d = length(uv - sun) / far;
    // The effect inside radius r, clear beyond it
    float r;
    if (wl_output == focused_output) {
        r = focused_output == previous_output ? 0.0 : 1.0 - p;
    } else if (wl_output == previous_output) {
        r = p;
    } else {
        return 1.0;
    }
    // An uneven, soft edge with a new shape every switch (see the other shaders)
    float seed = fract(sin(floor((time - focus_time) * 2.0) * 12.9898) * 43758.5453) * 100.0;
    float a = atan(uv.y - sun.y, uv.x - sun.x);
    float wobble = 0.09 * sin(a * 7.0 + seed * 1.7 + p * 1.5)
        + 0.06 * sin(a * 11.0 + seed * 4.1 - p * 2.0)
        + 0.025 * sin(st.x * 23.0 + seed) * sin(st.y * 19.0 - seed);
    d *= 1.0 + wobble;
    const float SOFT = 0.5;
    float edge = r * (1.16 + SOFT);
    return smoothstep(edge, edge - SOFT, d);
}


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

// Lighten like light added through glass (a screen blend), so darks lift gently
// and nothing clips to white
vec3 lighten(vec3 base, vec3 light) {
    return 1.0 - (1.0 - base) * (1.0 - clamp(light, 0.0, 1.0));
}

void main() {
    vec2 st = v_texcoord;
    vec3 clear = texture(tex, st).rgb;
    float shown = reach(st);
    if (shown <= 0.0) {
        fragColor = vec4(clear, 1.0);
        return;
    }

    vec2 uv = vec2(st.x * ASPECT, st.y);
    float t = time;

    // Where the sun is: just above the top edge, travelling left to right
    // through the day and highest at midday
    float day = clamp(DAY_FRACTION, 0.0, 1.0);
    vec2 sun = sunAt();
    float dist = length(uv - sun);

    // The light's colour with the time of day: golden and low in the morning,
    // whiter towards midday, rose-gold in the evening
    float height = sin(day * 3.1416);
    vec3 low = mix(vec3(1.0, 0.68, 0.38), vec3(1.0, 0.6, 0.5), smoothstep(0.3, 0.7, day));
    vec3 WARM = mix(low, vec3(1.0, 0.88, 0.72), smoothstep(0.25, 0.9, height));

    // Thin cloud passing: the light swells and fades slowly
    float breathe = 0.8 + 0.2 * sin(t * 0.07) * sin(t * 0.031 + 1.3);

    // The glow: strong near the sun, fading across the screen
    // The more cloud, the dimmer the glow (and the more beams, below)
    float clouds = clamp(CLOUD_COVER / 100.0, 0.0, 1.0);
    float glow = (0.24 * exp(-dist * 2.2) + 0.06 * exp(-dist * 0.6)) * breathe * mix(1.15, 0.6, clouds);
    vec3 col = lighten(clear, WARM * glow);

    // Sunbeams through gaps in moving cloud: the cloud drifts across the sun,
    // so beams slide sideways, widen and narrow, fade out and new ones open up.
    // Sometimes the cloud thins and there are several; sometimes none.
    vec2 away = uv - sun;
    float angle = atan(away.y, away.x);
    // Cloud time: runs faster the windier it is
    float ct = t * GUSTS;
    float gaps = 0.6 * noise(vec2(angle * 6.0 - WIND_WAY * ct * 0.045, ct * 0.012))
        + 0.4 * noise(vec2(angle * 13.0 - WIND_WAY * ct * 0.03, 7.0 + ct * 0.02));
    // None in a clear sky, more as the cloud comes in
    float plenty = smoothstep(0.0, 0.9, clouds);
    // How thick the cloud over the sun is right now: lower lets more beams through
    float cover = mix(1.15, 0.36, plenty) + 0.08 * sin(ct * 0.05) + 0.05 * sin(ct * 0.021 + 1.0);
    float softness = 0.12 + 0.1 * noise(vec2(angle * 4.0, ct * 0.03 + 9.0));
    float shafts = smoothstep(cover, cover + softness, gaps);
    // Each beam reaches its own distance, changing as the cloud moves
    float lengthNow = mix(0.6, 1.5, noise(vec2(angle * 5.0 - ct * 0.02, 3.0)));
    float beam = shafts * exp(-dist * mix(1.6, 0.9, height) / lengthNow) * smoothstep(0.0, 0.2, dist) * breathe;
    col = lighten(col, WARM * beam * 0.07 * mix(0.6, 1.5, plenty));

    // Flare ghosts: soft rings along the line from the sun through the middle
    vec2 middle = vec2(ASPECT * 0.5, 0.5);
    vec2 axis = middle - sun;
    for (int i = 0; i < 3; i++) {
        float k = i == 0 ? 0.55 : (i == 1 ? 1.05 : 1.45);
        float size = i == 0 ? 0.07 : (i == 1 ? 0.13 : 0.05);
        vec3 tint = i == 0 ? vec3(1.0, 0.85, 0.6) : (i == 1 ? vec3(0.6, 0.85, 1.0) : vec3(1.0, 0.7, 0.85));
        float d = length(uv - (sun + axis * k));
        float ring = smoothstep(size, size * 0.75, d) * (0.4 + 0.6 * smoothstep(size * 0.4, size, d));
        col = lighten(col, tint * ring * 0.055 * breathe);
    }

    // Dust and smudges on the glass, lit only where the light reaches
    float lit = clamp(glow * 4.0, 0.0, 1.0);
    if (lit > 0.01) {
        // Smudges: faint streaky haze
        float smudge = smoothstep(0.55, 0.8, fbm(uv * vec2(4.0, 7.0) + 3.0)) * 0.07;
        col = lighten(col, WARM * smudge * lit);
        // Specks: tiny points, a few catching the light now and then
        vec2 p = uv * 110.0;
        vec2 cell = floor(p);
        vec2 n = hash22(cell);
        if (hash12(cell + 4.2) < 0.05) {
            float r = mix(0.06, 0.16, n.x);
            float speck = smoothstep(r, r * 0.3, length(fract(p) - 0.5 - (n - 0.5) * 0.6));
            float glint = pow(max(0.0, sin(t * (0.4 + n.y) + n.x * 50.0)), 30.0);
            col = lighten(col, WARM * speck * lit * (0.14 + 0.55 * glint));
        }
    }

    // Dust motes floating in the air, seen where the light falls
    if (glow > 0.02) {
        vec2 drift = vec2(t * 0.006, -t * 0.003);
        vec2 p = (uv + drift) * 48.0;
        vec2 cell = floor(p);
        vec3 n = vec3(hash22(cell + 21.0), hash12(cell + 8.0));
        if (n.z < 0.3) {
            // Each wanders slowly within its patch of air
            vec2 o = (n.xy - 0.5) * 0.5 + 0.18 * vec2(sin(t * (0.15 + n.x * 0.2) + n.y * 30.0),
                                                   cos(t * (0.12 + n.y * 0.2) + n.x * 20.0));
            float r = mix(0.04, 0.09, n.x);
            float mote = smoothstep(r, r * 0.2, length(fract(p) - 0.5 - o));
            float twinkle = 0.7 + 0.3 * sin(t * (1.0 + n.y * 2.0) + n.x * 40.0);
            col = lighten(col, WARM * mote * twinkle * clamp(glow * 4.0 + beam * 3.0, 0.0, 1.0) * 0.4);
        }
    }

    fragColor = vec4(mix(clear, col, shown), 1.0);
}
