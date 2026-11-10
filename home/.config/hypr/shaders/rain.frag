#version 300 es
// Rain on the glass: drops that run down the whole screen along wandering
// paths, each leaving a thin wet trail, with a few small ones clinging between.
// Every drop is a small lens bending what's behind it, kept gentle so text stays
// readable. Only on the unfocused screens. Hyprland screen shader: needs
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

vec3 hash31(float p) {
    vec3 p3 = fract(vec3(p) * vec3(0.1031, 0.11369, 0.13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(vec3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

// The drops running down: their height on the glass at this point.
// uv.x runs across (0 to ASPECT), uv.y down the screen (0 at the top).
float running(vec2 uv, float t) {
    float cx = uv.x / ASPECT * COLUMNS;
    float column = floor(cx);
    float within = fract(cx) - 0.5;
    float h = 0.0;
    for (int k = 0; k < 2; k++) {
        vec3 n = hash31(column * 13.7 + float(k) * 91.3);
        if (n.z < mix(0.9, 0.46, HEAVY)) continue;         // dry columns: most in drizzle, few in a downpour
        float speed = mix(0.07, 0.14, n.x);                // 9 to 18 seconds top to bottom
        // A little stop-start, as drops catch and let go
        float head = fract(t * speed + n.y + 0.03 * sin(t * 1.3 + n.x * 40.0));
        head = head * 1.3 - 0.15;                          // enter above, leave below
        // The path wanders sideways as it comes down; the trail follows it
        float path = (n.z - 0.5) * 0.5 + sin(uv.y * 9.0 + n.x * 30.0) * 0.12
            + sin(uv.y * 23.0 + n.y * 17.0) * 0.04;
        float dx = (within - path) / COLUMNS * ASPECT;
        float dy = uv.y - head;
        float r = mix(0.0045, 0.008, n.y);
        float drop = smoothstep(r, r * 0.2, length(vec2(dx, dy * 0.75)));
        // Behind it (above), a thin streak that dries over a quarter screen
        float behind = step(dy, 0.0) * smoothstep(-0.25, 0.0, dy);
        float trail = smoothstep(r * 0.35, 0.0, abs(dx)) * behind * 0.35;
        h = max(h, max(drop, trail));
    }
    return h;
}

// Small drops that cling, appear and dry up
float clinging(vec2 uv, float t) {
    uv *= 28.0;
    vec2 id = floor(uv);
    uv = fract(uv) - 0.5;
    vec3 n = hash31(id.x * 107.45 + id.y * 3543.654);
    float d = length(uv - (n.xy - 0.5) * 0.7);
    float life = fract(t * 0.05 + n.z);
    float size = mix(0.08, 0.2, fract(n.z * 7.0));
    return smoothstep(size, 0.0, d) * smoothstep(0.0, 0.15, life) * smoothstep(1.0, 0.6, life)
        * step(mix(0.95, 0.8, HEAVY), fract(n.z * 13.0)) * 0.7;
}

float glass(vec2 uv, float t) {
    // The runs lean with the wind
    return max(running(vec2(uv.x - SLANT * uv.y, uv.y), t), clinging(uv, t));
}

void main() {
    vec3 clear = texture(tex, v_texcoord).rgb;
    float shown = reach(v_texcoord);
    if (shown <= 0.0) {
        fragColor = vec4(clear, 1.0);
        return;
    }

    vec2 uv = vec2(v_texcoord.x * ASPECT, FALL < 0.0 ? 1.0 - v_texcoord.y : v_texcoord.y);
    float t = time;

    vec2 e = vec2(0.0012, 0.0);
    float c = glass(uv, t);
    vec2 slope = vec2(glass(uv + e.xy, t) - c, glass(uv + e.yx, t) - c);

    vec2 bent = v_texcoord + vec2(slope.x, slope.y * FALL) * 0.1;
    vec4 col = texture(tex, bent);

    // A glint on each drop's upper edge, a faint shade on its lower one
    col.rgb += clamp(-slope.y * 8.0, 0.0, 1.0) * 0.07 * c;
    col.rgb *= 1.0 - clamp(slope.y * 8.0, 0.0, 1.0) * 0.08 * c;

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
