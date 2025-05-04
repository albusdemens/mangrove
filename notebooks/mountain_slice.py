import re
import math

def parse_obj(filename):
    """Parse OBJ file and return vertices and faces."""
    vertices = []
    faces = []
    
    with open(filename, 'r') as file:
        for line in file:
            line = line.strip()
            if line.startswith('v '):
                # Parse vertex line
                parts = line.split()
                x, y, z = float(parts[1]), float(parts[2]), float(parts[3])
                vertices.append((x, y, z))
            elif line.startswith('f '):
                # Parse face line
                parts = line.split()
                # Extract only the vertex indices (before any /)
                face = []
                for p in parts[1:]:
                    # Split by / and take only the first value (vertex index)
                    vertex_index = p.split('/')[0]
                    face.append(int(vertex_index) - 1)  # Convert 1-indexed to 0-indexed
                faces.append(face)
    
    return vertices, faces

def find_highest_point_and_tile(vertices):
    """Find the highest point and determine the nearest grid tile."""
    # Find highest point
    max_y = -float('inf')
    highest_vertex = None
    highest_idx = None
    
    for idx, (x, y, z) in enumerate(vertices):
        if y > max_y:
            max_y = y
            highest_vertex = (x, y, z)
            highest_idx = idx
    
    # The data shows a 40x40 grid pattern
    # Find the grid size based on vertex positions
    x_positions = sorted(list(set(x for x, _, _ in vertices)))
    z_positions = sorted(list(set(z for _, _, z in vertices)))
    
    grid_spacing_x = x_positions[1] - x_positions[0] if len(x_positions) > 1 else 0.123076923076923
    grid_spacing_z = z_positions[1] - z_positions[0] if len(z_positions) > 1 else 0.123076923076923
    
    # Find the nearest grid corner to the highest point
    hx, hz = highest_vertex[0], highest_vertex[2]
    corner_x = round(hx / grid_spacing_x) * grid_spacing_x
    corner_z = round(hz / grid_spacing_z) * grid_spacing_z
    
    return highest_vertex, (corner_x, corner_z)

def split_into_quadrants(vertices, faces, split_point):
    """Split vertices and faces into 4 quadrants based on split point."""
    split_x, split_z = split_point
    
    # Create quadrant structures
    quadrants = {
        'sw': {'vertices': [], 'faces': [], 'vertex_map': {}},  # x < 0, z < 0
        'se': {'vertices': [], 'faces': [], 'vertex_map': {}},  # x > 0, z < 0
        'nw': {'vertices': [], 'faces': [], 'vertex_map': {}},  # x < 0, z > 0
        'ne': {'vertices': [], 'faces': [], 'vertex_map': {}}   # x > 0, z > 0
    }
    
    # Classify vertices into quadrants
    for idx, (x, y, z) in enumerate(vertices):
        # Determine which quadrant this vertex belongs to
        if x <= split_x and z <= split_z:
            quad = 'sw'
        elif x > split_x and z <= split_z:
            quad = 'se'
        elif x <= split_x and z > split_z:
            quad = 'nw'
        else:  # x > split_x and z > split_z
            quad = 'ne'
        
        # Add vertex to appropriate quadrant
        new_idx = len(quadrants[quad]['vertices'])
        quadrants[quad]['vertices'].append((x, y, z))
        quadrants[quad]['vertex_map'][idx] = new_idx
    
    # Distribute faces to quadrants
    for face in faces:
        # Determine which quadrant this face belongs to
        # A face belongs to a quadrant if ANY of its vertices are in that quadrant
        for quad_name, quad_data in quadrants.items():
            face_vertices = []
            all_in_quadrant = True
            
            for v_idx in face:
                if v_idx in quad_data['vertex_map']:
                    face_vertices.append(quad_data['vertex_map'][v_idx])
                else:
                    all_in_quadrant = False
                    break
            
            if all_in_quadrant:
                quadrants[quad_name]['faces'].append(face_vertices)
                break
    
    return quadrants

def fill_sides(quadrants, split_point):
    """Add edges and faces to fill the sides where quadrants were split."""
    split_x, split_z = split_point
    
    # Function to find vertices on the split boundaries
    def vertices_on_boundary(vertices, axis, value, tolerance=1e-6):
        """Find vertices that lie on the boundary."""
        boundary_vertices = []
        for idx, vertex in enumerate(vertices):
            if axis == 'x' and abs(vertex[0] - value) < tolerance:
                boundary_vertices.append((idx, vertex))
            elif axis == 'z' and abs(vertex[2] - value) < tolerance:
                boundary_vertices.append((idx, vertex))
        return boundary_vertices
    
    # Collect boundary vertices for each quadrant
    boundaries = {}
    
    for quad_name, quad_data in quadrants.items():
        boundaries[quad_name] = {
            'edge_x': vertices_on_boundary(quad_data['vertices'], 'x', split_x),
            'edge_z': vertices_on_boundary(quad_data['vertices'], 'z', split_z)
        }
    
    # Create faces to connect adjacent quadrants
    def create_connecting_face(v1, v2, v3, v4):
        """Create a quad face connecting the boundary vertices."""
        return [v1, v2, v3, v4]
    
    # Connect quadrants
    # SW to SE connection (along z = split_z)
    if boundaries['sw']['edge_z'] and boundaries['se']['edge_z']:
        sw_edge_z = sorted(boundaries['sw']['edge_z'], key=lambda x: x[1][0])
        se_edge_z = sorted(boundaries['se']['edge_z'], key=lambda x: x[1][0])
        
        for i in range(min(len(sw_edge_z) - 1, len(se_edge_z) - 1)):
            # Create vertical face
            sw_bottom = sw_edge_z[i][0]
            sw_top = sw_edge_z[i + 1][0]
            se_bottom = se_edge_z[i][0]
            se_top = se_edge_z[i + 1][0]
            
            # Add face to both quadrants
            face = create_connecting_face(sw_bottom, se_bottom, se_top, sw_top)
            quadrants['sw']['faces'].append(face)
            quadrants['se']['faces'].append(face)
    
    # Similar connections for other boundaries...
    # This is a simplified version. For complete implementation, you'd need:
    # 1. NW to NE connection (along z = split_z)
    # 2. SW to NW connection (along x = split_x)
    # 3. SE to NE connection (along x = split_x)
    
    return quadrants

def write_obj(filename, vertices, faces):
    """Write vertices and faces to OBJ file."""
    with open(filename, 'w') as file:
        # Write header
        file.write("# OBJ file generated by Mountain Splitter\n")
        file.write(f"# Vertices: {len(vertices)}\n")
        file.write(f"# Faces: {len(faces)}\n\n")
        
        # Write vertices
        for x, y, z in vertices:
            file.write(f"v {x:.6f} {y:.6f} {z:.6f}\n")
        
        # Write faces (convert to 1-indexed)
        for face in faces:
            indices = " ".join(str(idx + 1) for idx in face)
            file.write(f"f {indices}\n")

def main():
    # Parse input OBJ
    input_file = "normalized_histogram_mountain.obj"
    vertices, faces = parse_obj(input_file)
    
    print(f"Loaded {len(vertices)} vertices and {len(faces)} faces")
    
    # Find highest point and split point
    highest_point, split_point = find_highest_point_and_tile(vertices)
    print(f"Highest point: {highest_point}")
    print(f"Split point: {split_point}")
    
    # Split into quadrants
    quadrants = split_into_quadrants(vertices, faces, split_point)
    
    # Fill sides (simplified version)
    quadrants = fill_sides(quadrants, split_point)
    
    # Write output files
    for quad_name, quad_data in quadrants.items():
        output_file = f"mountain_quadrant_{quad_name}.obj"
        write_obj(output_file, quad_data['vertices'], quad_data['faces'])
        print(f"Wrote {quad_name}: {len(quad_data['vertices'])} vertices, {len(quad_data['faces'])} faces")

if __name__ == "__main__":
    main()