shader_type spatial;

uniform vec4 low_color : source_color = vec4(0.9, 0.7, 0.9, 1.0);
uniform vec4 mid_color : source_color = vec4(0.7, 0.3, 0.7, 1.0);
uniform vec4 high_color : source_color = vec4(0.4, 0.0, 0.4, 1.0);
uniform float min_height = 0.0;
uniform float max_height = 20.0;
uniform bool use_contour_lines = true;
uniform float contour_spacing = 0.05;
uniform float contour_thickness = 0.005;

void vertex() {
    // Pass the vertex position to the fragment shader
    VERTEX = VERTEX;
}

void fragment() {
    // Get height from the model's Y position
    float height = VERTEX.y;

    // Calculate normalized height (0-1 range)
    float normalized_height = clamp((height - min_height) / (max_height - min_height), 0.0, 1.0);

    // Interpolate between the three colors based on height
    vec4 color;
    if (normalized_height < 0.5) {
        // Blend from low to mid
        color = mix(low_color, mid_color, normalized_height * 2.0);
    } else {
        // Blend from mid to high
        color = mix(mid_color, high_color, (normalized_height - 0.5) * 2.0);
    }

    // Add contour lines if enabled
    if (use_contour_lines) {
        float contour_value = mod(height, contour_spacing);
        if (contour_value < contour_thickness || contour_value > contour_spacing - contour_thickness) {
            // Darken color for contour lines
            color.rgb *= 0.7;
        }
    }

    // Apply the final color
    ALBEDO = color.rgb;
}