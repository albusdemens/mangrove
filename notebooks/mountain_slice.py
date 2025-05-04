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

def write_obj_file(filepath, vertices, faces, header_comment=""):
    """Write vertices and faces to an OBJ file."""
    with open(filepath, 'w') as f:
        if header_comment:
            f.write(f"# {header_comment}\n")
        
        # Write vertices
        for v in vertices:
            f.write(f"v {v[0]} {v[1]} {v[2]}\n")
        
        # Write faces
        for face in faces:
            if len(face) == 4:  # Quad
                f.write(f"f {face[0]} {face[1]} {face[2]} {face[3]}\n")
            elif len(face) == 3:  # Triangle
                f.write(f"f {face[0]} {face[1]} {face[2]}\n")

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

def determine_base_quadrant(bar_x, bar_z, center_x, center_z):
    """Determine initial quadrant based on center point."""
    if bar_x < center_x and bar_z < center_z:
        return 2  # Bottom-left
    elif bar_x < center_x and bar_z >= center_z:
        return 1  # Top-left
    elif bar_x >= center_x and bar_z < center_z:
        return 3  # Bottom-right
    else:  # bar_x >= center_x and bar_z >= center_z
        return 0  # Top-right

def split_mountain_with_extra_column(input_filepath, output_base_name):
    """Split mountain and add extra column to east (right) parts to eliminate gaps."""
    # Parse the OBJ file
    vertices, faces = parse_obj_file(input_filepath)
    print(f"Loaded {len(vertices)} vertices and {len(faces)} faces")
    
    # Group vertices by their bar position
    bars = group_vertices_by_bar(vertices)
    print(f"Found {len(bars)} histogram bars")
    
    # Find the highest point as the center
    center_x, center_z = find_highest_point_center(vertices)
    
    # Get sorted unique X positions
    x_positions = sorted(list(set(bar_x for (bar_x, _) in bars.keys())))
    
    # Find the center column index
    center_x_idx = min(range(len(x_positions)), key=lambda i: abs(x_positions[i] - center_x))
    center_col = x_positions[center_x_idx]
    
    print(f"Center column at X={center_col:.5f}")
    
    # First, assign tiles to base quadrants
    base_quadrant_bars = [[], [], [], []]
    
    for bar_pos in bars.keys():
        bar_x, bar_z = bar_pos
        quadrant = determine_base_quadrant(bar_x, bar_z, center_x, center_z)
        base_quadrant_bars[quadrant].append(bar_pos)
        
        # Debug: Print assignments for bars at center
        if abs(bar_x - center_x) < 1e-5 or abs(bar_z - center_z) < 1e-5:
            quadrant_names = ["top_right", "top_left", "bottom_left", "bottom_right"]
            print(f"  Bar at ({bar_x:.3f}, {bar_z:.3f}) -> {quadrant_names[quadrant]}")
    
    # Now, for east (right) parts, add the center column bars
    # bottom_right (3) and top_right (0) get extra column from left
    for bar_pos in base_quadrant_bars[2]:  # bottom_left
        bar_x, bar_z = bar_pos
        if abs(bar_x - center_col) < 1e-5:  # This is the center column
            base_quadrant_bars[3].append(bar_pos)  # Add to bottom_right
    
    for bar_pos in base_quadrant_bars[1]:  # top_left
        bar_x, bar_z = bar_pos
        if abs(bar_x - center_col) < 1e-5:  # This is the center column
            base_quadrant_bars[0].append(bar_pos)  # Add to top_right
    
    print(f"\nAfter adding center column to east parts:")
    print(f"top_right: {len(base_quadrant_bars[0])} bars")
    print(f"top_left: {len(base_quadrant_bars[1])} bars")
    print(f"bottom_left: {len(base_quadrant_bars[2])} bars")
    print(f"bottom_right: {len(base_quadrant_bars[3])} bars")
    
    # Create data structures for each quadrant
    quadrant_vertices = [[], [], [], []]  # List of vertices for each quadrant
    quadrant_faces = [[], [], [], []]  # List of faces for each quadrant
    vertex_index_map = [{}, {}, {}, {}]  # Maps original vertex index to new_index for each quadrant
    
    # Assign vertices to quadrants
    for quadrant in range(4):
        for bar_pos in base_quadrant_bars[quadrant]:
            for old_idx in bars[bar_pos]:
                # Only add if not already added to this quadrant
                if old_idx not in vertex_index_map[quadrant]:
                    new_idx = len(quadrant_vertices[quadrant])
                    quadrant_vertices[quadrant].append(vertices[old_idx])
                    vertex_index_map[quadrant][old_idx] = new_idx
    
    # Process faces and assign to appropriate quadrants
    for face in faces:
        # Check which quadrants have all vertices of this face
        for quadrant in range(4):
            all_vertices_in_quadrant = True
            for vertex_idx in face:
                adj_idx = vertex_idx - 1  # Convert from 1-indexed to 0-indexed
                if adj_idx not in vertex_index_map[quadrant]:
                    all_vertices_in_quadrant = False
                    break
            
            if all_vertices_in_quadrant:
                # Remap vertex indices for the quadrant
                new_face = []
                for vertex_idx in face:
                    adj_idx = vertex_idx - 1
                    new_idx = vertex_index_map[quadrant][adj_idx]
                    new_face.append(new_idx + 1)  # Convert back to 1-indexed
                
                quadrant_faces[quadrant].append(new_face)
    
    # Write the files for each quadrant
    quadrant_names = ["top_right", "top_left", "bottom_left", "bottom_right"]
    
    for i in range(4):
        output_filepath = f"{output_base_name}_{quadrant_names[i]}.obj"
        
        print(f"Created {output_filepath} with {len(quadrant_vertices[i])} vertices and {len(quadrant_faces[i])} faces")
        
        if len(quadrant_vertices[i]) > 0 and len(quadrant_faces[i]) > 0:
            write_obj_file(
                output_filepath,
                quadrant_vertices[i],
                quadrant_faces[i],
                f"Mountain quadrant: {quadrant_names[i]} - With extended column"
            )
        else:
            print(f"Warning: {quadrant_names[i]} quadrant has no valid geometry")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python split_mountain_extend.py input_file.obj [output_base_name]")
        print("Example: python split_mountain_extend.py mountain_histogram_40x40_godot.obj mountain_split")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_base = sys.argv[2] if len(sys.argv) > 2 else os.path.splitext(input_file)[0] + "_split"
    
    split_mountain_with_extra_column(input_file, output_base)