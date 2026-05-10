// --- Minimalist Helper Functions ---

// SDF for a rectangle (for the cursor head).
float getSdfRectangle(in vec2 p, in vec2 center, in vec2 size) {
    vec2 d = abs(p - center) - size;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// SDF for a capsule/thick line (for the trail).
float getSdfCapsule(in vec2 p, in vec2 a, in vec2 b, in float r) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h) - r;
}

// Normalizes coordinates from pixel space to a centered -1 to 1 space.
vec2 norm(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

// Easing function for a smooth fade-out.
float ease(float x) {
    return pow(1.0 - x, 3.0);
}


// --- Constants ---
const vec3 NORD_BLUE = vec3(0.533, 0.753, 0.816); // Hex: #88C0D0
const float OPACITY = 0.6;
const float DURATION = 0.1; // Trail fade duration in seconds

// --- Framerate Capping Constants ---
const float TARGET_FRAMERATE = 60.0;
const float FRAME_DURATION = 1.0 / TARGET_FRAMERATE;


void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Create a time variable that only updates at the target framerate
    float cappedTime = floor(iTime / FRAME_DURATION) * FRAME_DURATION;

    // 1. Setup Coordinates and Color
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    vec2 vu = norm(fragCoord, 1.);
    // --- Set the trail color to our hardcoded Nord Blue ---
    vec4 trailColor = vec4(NORD_BLUE, OPACITY);

    // 2. Normalize Cursor Data
    vec4 currentNorm = vec4(norm(iCurrentCursor.xy, 1.), norm(iCurrentCursor.zw, 0.));
    vec4 prevNorm = vec4(norm(iPreviousCursor.xy, 1.), norm(iPreviousCursor.zw, 0.));

    vec2 centerCurrent = currentNorm.xy - vec2(-0.5, 0.5) * currentNorm.zw;
    vec2 centerPrev = prevNorm.xy - vec2(-0.5, 0.5) * prevNorm.zw;
    vec2 size = currentNorm.zw * 0.5;

    // 3. Calculate SDF for the trail and cursor head
    float sdfTrail = getSdfCapsule(vu, centerPrev, centerCurrent, size.x);
    float sdfCursor = getSdfRectangle(vu, centerCurrent, size);
    
    // 4. Calculate Animation using the CAPPED time
    float progress = clamp((cappedTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
    float trailOpacity = ease(progress);

    // 5. Draw Shapes (in layers, background to foreground)
    float trailAmount = (1.0 - step(0.0, sdfTrail)) * trailOpacity;
    fragColor = mix(fragColor, trailColor, trailAmount);
    
    float cursorAmount = 1.0 - step(0.0, sdfCursor);
    fragColor = mix(fragColor, trailColor, cursorAmount);
}
