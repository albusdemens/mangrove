import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
from scipy.ndimage import gaussian_filter
import random
import time
from matplotlib.colors import LinearSegmentedColormap
import sys

def generate_detailed_mountain(grid_size=40, force_random=True):
    """
    Generate a mountain with a prominent central peak, clean borders,
    and additional minor peaks and isolated stones for visual interest.
    
    Parameters:
    -----------
    grid_size : int
        Resolution of the grid
    force_random : bool
        Whether to force randomness by using current time as seed
    
    Returns:
    --------
    height_map : numpy.ndarray
        2D array of the height data
    """
    # Force randomness by using current time as seed
    if force_random:
        current_time = int(time.time() * 1000) % 10000
        np.random.seed(current_time)
        random.seed(current_time + 1)
        print(f"Using random seed: {current_time}")
    
    # Create grid
    x = np.linspace(-3, 3, grid_size)
    y = np.linspace(-3, 3, grid_size)
    xx, yy = np.meshgrid(x, y)
    
    # Initialize height map
    height_map = np.zeros((grid_size, grid_size))
    
    # ---------------------------------------------------------
    # 1. Create the central mountain features
    # ---------------------------------------------------------
    
    # Use more central coordinates for the main peak
    center_x = np.random.uniform(-0.2, 0.2)
    center_y = np.random.uniform(-0.2, 0.2)
    
    # Create asymmetric shape for dramatic appearance
    sigma_x = np.random.uniform(0.5, 0.7)
    sigma_y = np.random.uniform(0.5, 0.7)
    
    # Add slight rotation for natural asymmetry
    rotation = np.random.uniform(0, 2*np.pi)
    dx = xx - center_x
    dy = yy - center_y
    dx_rot = dx * np.cos(rotation) - dy * np.sin(rotation)
    dy_rot = dx * np.sin(rotation) + dy * np.cos(rotation)
    
    # Create asymmetric distance field
    r = np.sqrt((dx_rot/sigma_x)**2 + (dy_rot/sigma_y)**2)
    
    # Add subtle directional warping for natural look
    warp_strength = np.random.uniform(0.05, 0.15)
    warp_freq_x = np.random.uniform(1.0, 2.0)
    warp_freq_y = np.random.uniform(1.0, 2.0)
    warp = warp_strength * np.sin(warp_freq_x * dx_rot) * np.cos(warp_freq_y * dy_rot)
    r += warp * np.clip(1.0 - r, 0, 1)
    
    # Create main peak with dramatic steepness
    main_peak_height = 1.0
    steepness = np.random.uniform(1.8, 2.5)
    
    main_peak = main_peak_height * np.exp(-r**steepness)
    
    # Ensure peak has a slightly sharper top
    sharp_factor = 1.2
    main_peak = np.power(main_peak, sharp_factor)
    
    # Add to height map
    height_map = np.maximum(height_map, main_peak)
    
    # ---------------------------------------------------------
    # 2. Add secondary features (smaller peaks, ridges)
    # ---------------------------------------------------------
    
    # Add several smaller peaks around the main one
    num_secondary_peaks = np.random.randint(3, 6)
    
    for _ in range(num_secondary_peaks):
        # Position relative to main peak and away from borders
        angle = np.random.uniform(0, 2*np.pi)
        distance = np.random.uniform(0.5, 1.2)
        
        peak_x = center_x + distance * np.cos(angle)
        peak_y = center_y + distance * np.sin(angle)
        
        # Ensure the peak isn't too close to borders
        if abs(peak_x) > 2.0 or abs(peak_y) > 2.0:
            continue
        
        # Smaller heights than main peak
        peak_height = np.random.uniform(0.3, 0.5)
        
        # Varied shapes
        sec_sigma_x = np.random.uniform(0.2, 0.4)
        sec_sigma_y = np.random.uniform(0.2, 0.4)
        
        # Distance from this peak
        sec_dx = xx - peak_x
        sec_dy = yy - peak_y
        
        # Add rotation
        sec_rot = np.random.uniform(0, 2*np.pi)
        sec_dx_rot = sec_dx * np.cos(sec_rot) - sec_dy * np.sin(sec_rot)
        sec_dy_rot = sec_dx * np.sin(sec_rot) + sec_dy * np.cos(sec_rot)
        
        sec_r = np.sqrt((sec_dx_rot/sec_sigma_x)**2 + (sec_dy_rot/sec_sigma_y)**2)
        
        # Create secondary peak
        sec_steepness = np.random.uniform(1.8, 2.5)
        secondary_peak = peak_height * np.exp(-sec_r**sec_steepness)
        
        # Add to height map
        height_map = np.maximum(height_map, secondary_peak)
    
    # Add ridge lines connecting to main peak
    num_ridges = np.random.randint(2, 4)
    
    for _ in range(num_ridges):
        # Start from central peak
        start_x = center_x
        start_y = center_y
        
        # Extend in random direction
        angle = np.random.uniform(0, 2*np.pi)
        length = np.random.uniform(0.8, 1.5)
        
        end_x = start_x + length * np.cos(angle)
        end_y = start_y + length * np.sin(angle)
        
        # Ensure endpoint is within safe area
        if abs(end_x) > 2.0 or abs(end_y) > 2.0:
            # Adjust end point to stay within bounds
            if abs(end_x) > 2.0:
                factor = 1.8 / abs(end_x)
                end_x *= factor
                end_y *= factor
            if abs(end_y) > 2.0:
                factor = 1.8 / abs(end_y)
                end_x *= factor
                end_y *= factor
        
        # Create a ridge with multiple points
        num_points = np.random.randint(4, 6)
        
        # Add some meandering to the ridge path
        control_x = np.linspace(start_x, end_x, num_points)
        control_y = np.linspace(start_y, end_y, num_points)
        
        # Add random variation but keep first point fixed at peak
        control_x[1:] += 0.15 * np.random.randn(num_points-1)
        control_y[1:] += 0.15 * np.random.randn(num_points-1)
        
        # Height decreases along ridge
        ridge_heights = np.linspace(0.6, 0.2, num_points)
        ridge_width = np.random.uniform(0.1, 0.15)
        
        for i in range(num_points):
            point_x = control_x[i]
            point_y = control_y[i]
            
            # Skip the first point as it's already covered by main peak
            if i == 0:
                continue
                
            # Distance from this ridge point
            r_ridge = np.sqrt((xx - point_x)**2 + (yy - point_y)**2)
            
            # Create a ridge segment with decreasing height from peak
            ridge_point = ridge_heights[i] * np.exp(-r_ridge**2 / ridge_width)
            
            # Add to height map
            height_map = np.maximum(height_map, ridge_point)
    
    # ---------------------------------------------------------
    # 3. Add minor peaks scattered around the mountain
    # ---------------------------------------------------------
    
    num_minor_peaks = np.random.randint(5, 10)
    
    for _ in range(num_minor_peaks):
        # Position these at intermediate distances from center
        angle = np.random.uniform(0, 2*np.pi)
        # Distance varies - some closer to main peak, some further out
        distance = np.random.uniform(0.8, 2.0)
        
        peak_x = center_x + distance * np.cos(angle)
        peak_y = center_y + distance * np.sin(angle)
        
        # Ensure the peak isn't too close to borders
        if abs(peak_x) > 2.0 or abs(peak_y) > 2.0:
            continue
        
        # These peaks are smaller than secondary peaks
        peak_height = np.random.uniform(0.15, 0.3)
        
        # More varied shapes - some sharper, some more gradual
        minor_sigma = np.random.uniform(0.05, 0.2)
        
        # Distance from this peak
        r_minor = np.sqrt((xx - peak_x)**2 + (yy - peak_y)**2)
        
        # Create minor peak with variable steepness
        minor_steepness = np.random.uniform(1.5, 3.0)
        minor_peak = peak_height * np.exp(-r_minor**2 / minor_sigma)
        minor_peak = minor_peak ** minor_steepness  # Make some peaks sharper
        
        # Add to height map
        height_map = np.maximum(height_map, minor_peak)
    
    # ---------------------------------------------------------
    # 4. Add isolated stones/rocks scattered across the terrain
    # ---------------------------------------------------------
    
    num_stones = np.random.randint(15, 25)
    
    for _ in range(num_stones):
        # Scatter these more widely, but keep away from borders
        angle = np.random.uniform(0, 2*np.pi)
        distance = np.random.uniform(0.2, 2.3)
        
        stone_x = center_x + distance * np.cos(angle)
        stone_y = center_y + distance * np.sin(angle)
        
        # Safety check for borders
        if abs(stone_x) > 2.2 or abs(stone_y) > 2.2:
            continue
        
        # These are much smaller than minor peaks
        stone_height = np.random.uniform(0.05, 0.15)
        
        # Stones are small and sharp
        stone_sigma = np.random.uniform(0.02, 0.08)
        
        # Distance from this stone
        r_stone = np.sqrt((xx - stone_x)**2 + (yy - stone_y)**2)
        
        # Create stone with high steepness for sharpness
        stone_steepness = np.random.uniform(2.0, 4.0)
        stone = stone_height * np.exp(-r_stone**2 / stone_sigma)
        stone = stone ** stone_steepness  # Very sharp
        
        # Add to height map
        height_map = np.maximum(height_map, stone)
    
    # ---------------------------------------------------------
    # 5. Add boulder fields (clusters of small rocks)
    # ---------------------------------------------------------
    
    num_boulder_fields = np.random.randint(3, 6)
    
    for _ in range(num_boulder_fields):
        # Position boulder fields at various distances
        angle = np.random.uniform(0, 2*np.pi)
        distance = np.random.uniform(0.5, 1.8)
        
        field_center_x = center_x + distance * np.cos(angle)
        field_center_y = center_y + distance * np.sin(angle)
        
        # Safety check for borders
        if abs(field_center_x) > 2.0 or abs(field_center_y) > 2.0:
            continue
        
        # Create 5-10 boulders in this field
        num_boulders = np.random.randint(5, 10)
        
        for i in range(num_boulders):
            # Position randomly within the field
            boulder_x = field_center_x + np.random.uniform(-0.2, 0.2)
            boulder_y = field_center_y + np.random.uniform(-0.2, 0.2)
            
            # Safety check again
            if abs(boulder_x) > 2.2 or abs(boulder_y) > 2.2:
                continue
            
            # Small height
            boulder_height = np.random.uniform(0.04, 0.1)
            
            # Very small radius
            boulder_sigma = np.random.uniform(0.01, 0.05)
            
            # Distance from this boulder
            r_boulder = np.sqrt((xx - boulder_x)**2 + (yy - boulder_y)**2)
            
            # Create boulder
            boulder_steepness = np.random.uniform(2.5, 3.5)
            boulder = boulder_height * np.exp(-r_boulder**2 / boulder_sigma)
            boulder = boulder ** boulder_steepness
            
            # Add to height map
            height_map = np.maximum(height_map, boulder)
    
    # ---------------------------------------------------------
    # 6. Add surface details
    # ---------------------------------------------------------
    
    # Create multi-scale texture
    texture_layers = 3
    texture = np.zeros_like(height_map)
    
    for i in range(texture_layers):
        freq = 2**i
        amp = 0.05 * (0.5**i)
        
        noise_layer = amp * np.random.rand(grid_size, grid_size)
        noise_layer = gaussian_filter(noise_layer, sigma=1.0/(freq*0.6))
        texture += noise_layer
    
    # Create a mask that fades out toward the borders
    border_distance = np.maximum(
        np.abs(xx / 3), np.abs(yy / 3)
    )
    
    # Create smooth falloff from center to borders
    texture_mask = np.clip(1.0 - border_distance**2, 0, 1)
    
    # Apply texture with height-dependent intensity and border mask
    gradient_x, gradient_y = np.gradient(height_map)
    slope = np.sqrt(gradient_x**2 + gradient_y**2)
    slope_factor = np.clip(slope / 0.5, 0, 1)
    
    # Apply texture primarily to slopes and fade out near borders
    height_map += texture * slope_factor * 0.4 * texture_mask
    
    # ---------------------------------------------------------
    # 7. Ensure clean borders with explicit falloff
    # ---------------------------------------------------------
    
    # Create a stronger border falloff mask
    border_factor = 0.8
    edge_distance = np.maximum(
        (np.abs(xx) - 2.5) / 0.5,
        (np.abs(yy) - 2.5) / 0.5
    )
    
    # Create a smooth falloff that's 1 in the center region and 0 at borders
    border_mask = np.clip(1.0 - edge_distance, 0, 1)
    
    # Apply border mask to entire height map
    height_map = height_map * border_mask
    
    # Double-check that borders are exactly zero
    margin = 2  # pixels
    height_map[0:margin, :] = 0
    height_map[-margin:, :] = 0
    height_map[:, 0:margin] = 0
    height_map[:, -margin:] = 0
    
    # Scale heights for better visualization
    max_height = np.random.uniform(12, 16)
    height_map = height_map * max_height
    
    # Save the raw data
    np.save('detailed_mountain_data.npy', height_map)
    
    return height_map

def export_histogram_obj_for_godot(height_map, filename='histogram_mountain_godot.obj', threshold=0.05):
    """
    Export the mountain as a histogram-style OBJ file with vertical bars,
    with coordinates adjusted for Godot's coordinate system (Y-up).
    
    Parameters:
    -----------
    height_map : numpy.ndarray
        2D height map data
    filename : str
        Output OBJ filename
    threshold : float
        Minimum height threshold to include a bar (helps reduce file size)
    """
    # Get dimensions
    grid_size = height_map.shape[0]
    x = np.linspace(-3, 3, grid_size)
    y = np.linspace(-3, 3, grid_size)
    
    # Calculate bar dimensions
    dx = (x[1] - x[0]) * 0.8  # Slightly smaller for gap effect
    dy = (y[1] - y[0]) * 0.8
    
    # Open file for writing
    with open(filename, 'w') as f:
        # Write header
        f.write("# Mountain Histogram OBJ file for Godot (Y-up coordinate system)\n")
        f.write(f"# Grid size: {grid_size}x{grid_size}\n")
        
        # Track vertex indices
        vertex_count = 1  # OBJ is 1-indexed
        bar_data = []  # Store data for each bar to write faces later
        
        # Generate vertices and faces for each bar
        for i in range(grid_size):
            for j in range(grid_size):
                height = height_map[i, j]
                
                # Skip very low heights to reduce file size
                if height < threshold:
                    continue
                
                # Calculate bar coordinates
                x_min = x[j] - dx/2
                x_max = x[j] + dx/2
                z_min = y[i] - dy/2  # Z in Godot is like Y in our original system
                z_max = y[i] + dy/2
                y_min = 0.0          # Y in Godot is up (our Z)
                y_max = height
                
                # Store the base vertex index for this bar
                base_vertex = vertex_count
                
                # Write the 8 vertices for this bar (with Y up for Godot)
                # Bottom 4 vertices
                f.write(f"v {x_min} {y_min} {z_min}\n")  # 1
                f.write(f"v {x_max} {y_min} {z_min}\n")  # 2
                f.write(f"v {x_max} {y_min} {z_max}\n")  # 3
                f.write(f"v {x_min} {y_min} {z_max}\n")  # 4
                # Top 4 vertices
                f.write(f"v {x_min} {y_max} {z_min}\n")  # 5
                f.write(f"v {x_max} {y_max} {z_min}\n")  # 6
                f.write(f"v {x_max} {y_max} {z_max}\n")  # 7
                f.write(f"v {x_min} {y_max} {z_max}\n")  # 8
                
                # Store bar data for writing faces later
                bar_data.append(base_vertex)
                
                # Update vertex count
                vertex_count += 8
        
        # Write faces for all bars (face winding order is important)
        for base_vertex in bar_data:
            # Bottom face
            f.write(f"f {base_vertex} {base_vertex+1} {base_vertex+2} {base_vertex+3}\n")
            # Top face
            f.write(f"f {base_vertex+4} {base_vertex+5} {base_vertex+6} {base_vertex+7}\n")
            # Side 1
            f.write(f"f {base_vertex} {base_vertex+4} {base_vertex+5} {base_vertex+1}\n")
            # Side 2
            f.write(f"f {base_vertex+1} {base_vertex+5} {base_vertex+6} {base_vertex+2}\n")
            # Side 3
            f.write(f"f {base_vertex+2} {base_vertex+6} {base_vertex+7} {base_vertex+3}\n")
            # Side 4
            f.write(f"f {base_vertex+3} {base_vertex+7} {base_vertex+4} {base_vertex}\n")
    
    print(f"Godot-compatible histogram OBJ file saved as {filename}")
    return filename

def visualize_and_export_mountain(grid_size=40):
    """
    Generate a mountain, visualize it, and export it as a Godot-compatible
    histogram-style OBJ.
    """
    # Generate mountain
    print(f"Generating mountain with grid size {grid_size}...")
    height_map = generate_detailed_mountain(grid_size=grid_size, force_random=True)
    
    # Create histogram visualization (for reference)
    print("Creating histogram visualization...")
    fig_histogram = plt.figure(figsize=(12, 10), facecolor='white')
    ax_hist = fig_histogram.add_subplot(111, projection='3d')
    
    # Get grid dimensions
    x = np.linspace(-3, 3, grid_size)
    y = np.linspace(-3, 3, grid_size)
    
    # Prepare data for histogram
    xpos, ypos = np.meshgrid(x, y)
    xpos = xpos.flatten()
    ypos = ypos.flatten()
    zpos = np.zeros_like(xpos)
    
    dx = (x[1] - x[0]) * 0.8
    dy = (y[1] - y[0]) * 0.8
    dz = height_map.flatten()
    
    # Set colors
    max_height_value = np.max(dz)
    colors = plt.cm.Blues(dz / max_height_value)
    
    # Create the histogram bars
    ax_hist.bar3d(xpos, ypos, zpos, dx, dy, dz, color=colors, shade=True, alpha=0.8, zsort='average')
    
    # Set labels and title
    ax_hist.set_xlabel('X', fontsize=12, labelpad=10)
    ax_hist.set_ylabel('Z', fontsize=12, labelpad=10)  # Changed to Z for Godot's coordinate system reference
    ax_hist.set_zlabel('Y (Height)', fontsize=12, labelpad=10)  # Changed to Y for Godot's coordinate system reference
    ax_hist.set_title(f"Detailed Mountain - Histogram View (Grid: {grid_size}x{grid_size})", fontsize=14, pad=20)
    
    # Set view angle
    ax_hist.view_init(30, 45)
    ax_hist.grid(False)
    
    # Add stats box
    stats_text = (
        f"h2\n"
        f"Entries     {grid_size * grid_size}\n"
        f"Grid Size   {grid_size}x{grid_size}\n"
        f"Peak       {np.max(height_map):.2f}"
    )
    
    ax_hist.text2D(0.75, 0.95, stats_text, transform=ax_hist.transAxes, 
                fontsize=10, family='monospace',
                bbox=dict(facecolor='white', edgecolor='black', alpha=0.7))
    
    # Set axis limits
    buffer = 0.5
    ax_hist.set_xlim(np.min(x) - buffer, np.max(x) + buffer)
    ax_hist.set_ylim(np.min(y) - buffer, np.max(y) + buffer)
    
    plt.tight_layout()
    plt.savefig(f'mountain_histogram_{grid_size}x{grid_size}.png', dpi=300, bbox_inches='tight')
    
    # Export as Godot-compatible OBJ file
    print("Exporting Godot-compatible OBJ file...")
    export_histogram_obj_for_godot(height_map, f'mountain_histogram_{grid_size}x{grid_size}_godot.obj', threshold=0.1)
    
    print("Done! Check the output files.")
    plt.show()
    return height_map

if __name__ == "__main__":
    # Default grid size is 40 if no argument is provided
    grid_size = 40
    
    # Check if grid size was provided as command line argument
    if len(sys.argv) > 1:
        try:
            grid_size = int(sys.argv[1])
            print(f"Using grid size: {grid_size}")
        except ValueError:
            print(f"Invalid grid size: {sys.argv[1]}, using default: {grid_size}")
    
    # Generate mountain with specified grid size
    visualize_and_export_mountain(grid_size)