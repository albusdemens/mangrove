shader_type spatial;

uniform vec3 highest_point;
uniform vec3 band1_normal;
uniform float band1_width = 0.1; // Adjust as needed
uniform vec3 band2_normal;
uniform float band2_width = 0.1; // Adjust as needed
uniform vec3 band_color: source_color = vec3(1.0, 1.0, 0.0); // Yellow
uniform vec3 quadrant1_color: source_color = vec3(0.8, 0.2, 0.2); // Reddish
uniform vec3 quadrant2_color: source_color = vec3(0.2, 0.8, 0.2); // Greenish
uniform vec3 quadrant3_color: source_color = vec3(0.2, 0.2, 0.8); // Blueish
uniform vec3 quadrant4_color: source_color = vec3(0.8, 0.8, 0.2); // Yellowish
uniform sampler2D texture_albedo: source_color; // Declare the albedo texture

void fragment() {
    // Get the world-space position of the current fragment
    vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Calculate signed distances to the band planes
    float dist1 = dot(world_position - highest_point, band1_normal);
    float dist2 = dot(world_position - highest_point, band2_normal);

    // Determine which band the fragment belongs to
    float band1_factor = step(abs(dist1), band1_width);
    float band2_factor = step(abs(dist2), band2_width);

    // Determine the quadrant based on the signs of the distances
    vec3 albedo;
    if (dist1 > 0.0 && dist2 > 0.0) {
        albedo = quadrant1_color;
    } else if (dist1 < 0.0 && dist2 > 0.0) {
        albedo = quadrant2_color;
    } else if (dist1 < 0.0 && dist2 < 0.0) {
        albedo = quadrant3_color;
    } else if (dist1 > 0.0 && dist2 < 0.0) {
        albedo = quadrant4_color;
    } else {
        albedo = texture(texture_albedo, UV).rgb; // Sample the albedo texture
    }

    // Apply the band color over the quadrant color
    ALBEDO = mix(albedo, band_color, max(band1_factor, band2_factor));
}