import numpy as np
import os
import sys

def parse_obj_file(filepath):
    """Parse OBJ file and extract vertices and faces."""
    vertices = []
    faces = []
    
    with open(filepath, 'r') as f:
        for line in f:
            if line.startswith('v '):
                # Parse vertex
                parts = line.split()
                vertices.append([float(parts[1]), float(parts[2]), float(parts[3])])
            elif line.startswith('f '):
                # Parse face
                parts = line.split()
                face = []
                for part in parts[1:]:
                    # Handle different face formats (vertex/texture/normal)
                    vertex_index = part.split('/')[0]
                    face.append(int(vertex_index))
                faces.append(face)
    
    return np.array(vertices), faces

def find_highest_point_center(vertices):
    """Find the highest point as the center for cutting."""
    # Find the highest point
    max_y_idx = np.argmax(vertices[:, 1])  # Y is height
    highest_point = vertices[max_y_idx]
    
    # Return the X and Z coordinates
    center_x = highest_point[0]
    center_z = highest_point[2]
    
    print(f"Highest point found at X={center_x:.5f}, Z={center_z:.5f}, Y={highest_point[1]:.5f}")
    return center_x, center_z

def group_vertices_by_bar(vertices, tolerance=1e-5):
    """Group vertices that belong to the same histogram bar."""
    bars = {}  # Key: (x, z) position, Value: list of vertex indices
    
    for idx, vertex in enumerate(vertices):
        # Round to avoid floating point precision issues
        bar_x = round(vertex[0], 6)
        bar_z = round(vertex[2], 6)
        bar_key = (bar_x, bar_z)
        
        if bar_key not in bars:
            bars[bar_key] = []
        bars[bar_key].append(idx)
    
    return bars

def analyze_bars_around_center(bars, center_x, center_z):
    """Analyze bars around the center to understand the gap."""
    print(f"\nAnalyzing bars around center X={center_x:.5f}, Z={center_z:.5f}")
    
    # Find the nearest bars to the center
    distances = []
    for (bar_x, bar_z) in bars.keys():
        dist = (bar_x - center_x)**2 + (bar_z - center_z)**2
        distances.append(((bar_x, bar_z), dist))
    
    distances.sort(key=lambda x: x[1])
    
    print("\nNearest 10 bars to center:")
    for i, ((bar_x, bar_z), dist) in enumerate(distances[:10]):
        print(f"{i}: Bar at ({bar_x:.3f}, {bar_z:.3f}), distance={dist:.3f}")
    
    # Find unique X values near center
    x_values = sorted(list(set(bar_x for (bar_x, _) in bars.keys())))
    x_idx = min(range(len(x_values)), key=lambda i: abs(x_values[i] - center_x))
    
    print(f"\nUnique X values near center:")
    for i in range(max(0, x_idx-2), min(len(x_values), x_idx+3)):
        is_center = x_values[i] == x_values[x_idx]
        print(f"  X={x_values[i]:.5f} {'<-- CENTER' if is_center else ''}")
    
    # Check if center_x falls exactly on a grid point or between grid points
    nearest_x = x_values[x_idx]
    if abs(nearest_x - center_x) < 1e-5:
        print(f"\nCenter X={center_x:.5f} falls EXACTLY on grid point X={nearest_x:.5f}")
    else:
        print(f"\nCenter X={center_x:.5f} falls BETWEEN grid points")
        if x_idx < len(x_values) - 1:
            print(f"Between X={x_values[x_idx]:.5f} and X={x_values[x_idx+1]:.5f}")
            
    # Same for Z
    z_values = sorted(list(set(bar_z for (_, bar_z) in bars.keys())))
    z_idx = min(range(len(z_values)), key=lambda i: abs(z_values[i] - center_z))
    
    print(f"\nUnique Z values near center:")
    for i in range(max(0, z_idx-2), min(len(z_values), z_idx+3)):
        is_center = z_values[i] == z_values[z_idx]
        print(f"  Z={z_values[i]:.5f} {'<-- CENTER' if is_center else ''}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python debug_mountain_gap.py input_file.obj")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Parse the OBJ file
    vertices, faces = parse_obj_file(input_file)
    print(f"Loaded {len(vertices)} vertices and {len(faces)} faces")
    
    # Group vertices by their bar position
    bars = group_vertices_by_bar(vertices)
    print(f"Found {len(bars)} histogram bars")
    
    # Find the highest point as the center
    center_x, center_z = find_highest_point_center(vertices)
    
    # Analyze bars around the center
    analyze_bars_around_center(bars, center_x, center_z)

if __name__ == "__main__":
    main()