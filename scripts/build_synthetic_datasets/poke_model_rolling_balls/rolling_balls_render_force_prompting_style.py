#!/usr/bin/env python3
"""
Rolling balls renderer that matches force-prompting's original file structure
Generates RGB frames as frameXXXX.png with depth and sketch in subdirectories
"""

import bpy
import os
import sys
import math
import random
import json
import argparse
import glob
from pathlib import Path

# Import mathutils only if available (in Blender)
try:
    from mathutils import Vector
except ImportError:
    Vector = None

# Add GPT4Motion BlenderTool to path if needed
script_dir = os.path.dirname(os.path.abspath(__file__))
gpt4motion_path = os.path.abspath(os.path.join(script_dir, '../../../GPT4Motion/PhysicsGeneration'))
if os.path.exists(gpt4motion_path):
    sys.path.insert(0, gpt4motion_path)
    from BlenderTool.utils import *
    # Override ASSETS_PATH with absolute path
    ASSETS_PATH = os.path.join(gpt4motion_path, 'BlenderTool/assets/')
    USE_GPT4MOTION = True
else:
    USE_GPT4MOTION = False

# Hard-coded paths to texture files (like in original rolling_balls.py)
TEXTURE_PATH = os.path.join(script_dir, "football_textures")
GROUND_TEXTURE_BASE_PATH = os.path.join(script_dir, "ground_textures")

def apply_ball_textures(obj, texture_folder=None):
    """Apply textures to the given ball object using files from a chosen texture folder."""
    if not obj:
        print("Warning: Target object not found")
        return False

    if "bowling_ball" in obj.name.lower():
        # Apply bowling ball appearance (solid color and shiny)
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.shade_smooth()

        # Add subdivision surface for smoother appearance
        if not any(mod.type == 'SUBSURF' for mod in obj.modifiers):
            subsurf = obj.modifiers.new(name="Subsurf", type='SUBSURF')
            subsurf.levels = 2
            subsurf.render_levels = 2

        # Create material
        mat = bpy.data.materials.new(name="Bowling_Ball_Material")
        obj.data.materials.clear()
        obj.data.materials.append(mat)

        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()

        principled = nodes.new(type='ShaderNodeBsdfPrincipled')
        principled.location = (0, 0)
        output = nodes.new(type='ShaderNodeOutputMaterial')
        output.location = (300, 0)
        links.new(principled.outputs['BSDF'], output.inputs['Surface'])

        # Choose a random solid color
        solid_colors = [
            (0.0, 0.0, 0.0, 1.0),      # Jet Black
            (0.1, 0.1, 0.5, 1.0),      # Deep Blue
            (0.6, 0.0, 0.0, 1.0),      # Dark Red
            (0.1, 0.4, 0.1, 1.0),      # Forest Green
            (0.4, 0.0, 0.4, 1.0),      # Purple
            (0.3, 0.3, 0.3, 1.0),      # Graphite Gray
            (0.8, 0.5, 0.0, 1.0),      # Bronze
            (1.0, 0.0, 0.0, 1.0),      # Bright Red
            (0.0, 0.0, 1.0, 1.0),      # Royal Blue
            (0.0, 1.0, 0.0, 1.0),      # Vivid Green
            (1.0, 1.0, 0.0, 1.0),      # Neon Yellow
            (1.0, 0.65, 0.0, 1.0),     # Vibrant Orange
        ]

        # Add more black bowling balls
        solid_colors = solid_colors + [(0.0, 0.0, 0.0, 1.0)] * 20

        base_color = random.choice(solid_colors)
        principled.inputs['Base Color'].default_value = base_color
        principled.inputs['Roughness'].default_value = 0.05  # Make it shiny

        print(f"Applied bowling ball appearance with color {base_color}.")
        return True
    
    # Football/soccer ball texture
    if not os.path.exists(TEXTURE_PATH):
        print(f"Warning: Texture path {TEXTURE_PATH} not found, using default material")
        return False
    
    # Randomly pick a folder if not specified
    if texture_folder is None:
        try:
            subfolders = [f for f in os.listdir(TEXTURE_PATH) if os.path.isdir(os.path.join(TEXTURE_PATH, f))]
            if not subfolders:
                print(f"Warning: No texture subfolders found in {TEXTURE_PATH}")
                return False
            texture_folder = random.choice(subfolders)
        except Exception as e:
            print(f"Error accessing texture folders: {e}")
            return False

    pattern_path = os.path.join(TEXTURE_PATH, texture_folder)

    def find_texture(name_base):
        """Find the first matching file with the given base name regardless of extension."""
        matches = glob.glob(os.path.join(pattern_path, f"{name_base}.*"))
        return matches[0] if matches else None

    # Resolve texture file paths
    diffuse_path = find_texture("pattern")
    normal_path = find_texture("normal")
    roughness_path = find_texture("rough")

    # Create a unique material
    mat = bpy.data.materials.new(name=f"Football_Material_{texture_folder}")
    obj.data.materials.clear()
    obj.data.materials.append(mat)

    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    principled = nodes.new(type='ShaderNodeBsdfPrincipled')
    principled.location = (0, 0)
    output = nodes.new(type='ShaderNodeOutputMaterial')
    output.location = (300, 0)
    links.new(principled.outputs['BSDF'], output.inputs['Surface'])

    # Apply diffuse texture
    if diffuse_path and os.path.exists(diffuse_path):
        tex_diffuse = nodes.new(type='ShaderNodeTexImage')
        tex_diffuse.location = (-300, 100)
        tex_diffuse.image = bpy.data.images.load(diffuse_path)
        
        # Create a Hue/Saturation node for color variation
        hue_sat = nodes.new(type='ShaderNodeHueSaturation')
        hue_sat.location = (-200, 100)
        
        # Random variation parameters
        hue_shift = random.uniform(0.85, 1.15)
        sat_shift = random.uniform(0.9, 1.1)
        val_shift = random.uniform(0.9, 1.1)
        
        hue_sat.inputs['Hue'].default_value = hue_shift
        hue_sat.inputs['Saturation'].default_value = sat_shift
        hue_sat.inputs['Value'].default_value = val_shift
        
        links.new(tex_diffuse.outputs['Color'], hue_sat.inputs['Color'])
        links.new(hue_sat.outputs['Color'], principled.inputs['Base Color'])
        
        print(f"Applied diffuse texture: {diffuse_path}")

    # Apply normal texture
    if normal_path and os.path.exists(normal_path):
        tex_normal = nodes.new(type='ShaderNodeTexImage')
        tex_normal.location = (-300, -100)
        tex_normal.image = bpy.data.images.load(normal_path)
        normal_map = nodes.new(type='ShaderNodeNormalMap')
        normal_map.location = (-100, -100)
        links.new(tex_normal.outputs['Color'], normal_map.inputs['Color'])
        links.new(normal_map.outputs['Normal'], principled.inputs['Normal'])
        print(f"Applied normal texture: {normal_path}")

    # Apply roughness texture
    if roughness_path and os.path.exists(roughness_path):
        tex_roughness = nodes.new(type='ShaderNodeTexImage')
        tex_roughness.location = (-300, -300)
        tex_roughness.image = bpy.data.images.load(roughness_path)
        links.new(tex_roughness.outputs['Color'], principled.inputs['Roughness'])
        print(f"Applied roughness texture: {roughness_path}")

    return True

def apply_ground_textures():
    """Apply randomly selected ground textures to the plane"""
    # Find the floor plane
    floor = None
    for obj in bpy.data.objects:
        if obj.type == 'MESH' and (obj.name.startswith('Floor') or 'floor' in obj.name.lower() or 'plane' in obj.name.lower()):
            floor = obj
            break
    
    if not floor:
        print("Warning: Floor object not found in scene")
        return False
    
    if not os.path.exists(GROUND_TEXTURE_BASE_PATH):
        print(f"Warning: Ground texture path {GROUND_TEXTURE_BASE_PATH} not found")
        return False
    
    # Get available ground texture directories
    try:
        ground_types = [d for d in os.listdir(GROUND_TEXTURE_BASE_PATH) 
                       if os.path.isdir(os.path.join(GROUND_TEXTURE_BASE_PATH, d))]
        if not ground_types:
            print(f"No ground texture directories found in {GROUND_TEXTURE_BASE_PATH}")
            return False
        
        # Randomly select a ground type
        selected_ground = random.choice(ground_types)
        texture_path = os.path.join(GROUND_TEXTURE_BASE_PATH, selected_ground, "textures")
        
        print(f"Selected ground texture: {selected_ground}")
        
        # Get or create the material for the plane
        if len(floor.material_slots) == 0:
            mat = bpy.data.materials.new(name="Ground_Material")
            floor.data.materials.append(mat)
        else:
            mat = floor.material_slots[0].material
            if not mat:
                mat = bpy.data.materials.new(name="Ground_Material")
                floor.material_slots[0].material = mat
        
        # Enable nodes for the material
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        
        # Clear existing nodes
        for node in nodes:
            nodes.remove(node)
        
        # Create the principled BSDF shader
        principled = nodes.new(type='ShaderNodeBsdfPrincipled')
        principled.location = (0, 0)
        
        # Create output node
        output = nodes.new(type='ShaderNodeOutputMaterial')
        output.location = (300, 0)
        
        # Link principled to output
        links.new(principled.outputs['BSDF'], output.inputs['Surface'])
        
        # Add texture coordinate and mapping nodes
        tex_coord = nodes.new(type='ShaderNodeTexCoord')
        tex_coord.location = (-800, 0)
        
        mapping = nodes.new(type='ShaderNodeMapping')
        mapping.location = (-600, 0)
        mapping.inputs['Scale'].default_value[0] = 5.0
        mapping.inputs['Scale'].default_value[1] = 5.0
        
        links.new(tex_coord.outputs['UV'], mapping.inputs['Vector'])
        
        # Try to load textures
        texture_files = glob.glob(os.path.join(texture_path, "*"))
        if texture_files:
            # Load first available texture
            texture_file = texture_files[0]
            tex_diffuse = nodes.new(type='ShaderNodeTexImage')
            tex_diffuse.location = (-400, 200)
            tex_diffuse.image = bpy.data.images.load(texture_file)
            links.new(mapping.outputs['Vector'], tex_diffuse.inputs['Vector'])
            links.new(tex_diffuse.outputs['Color'], principled.inputs['Base Color'])
            print(f"Applied ground texture: {texture_file}")
        
        return True
        
    except Exception as e:
        print(f"Error applying ground textures: {e}")
        return False

def setup_freestyle_for_sketch():
    """Setup Freestyle for proper sketch/edge detection"""
    scene = bpy.context.scene
    
    # Enable Freestyle
    scene.render.use_freestyle = True
    scene.render.line_thickness_mode = 'ABSOLUTE'
    scene.render.line_thickness = 1.0  # Fine line thickness
    
    # Get the view layer
    view_layer = scene.view_layers["ViewLayer"]
    view_layer.use_pass_z = True
    view_layer.freestyle_settings.as_render_pass = True
    
    # Setup freestyle line sets
    freestyle_settings = view_layer.freestyle_settings
    
    # Clear existing line sets by removing them individually
    while len(freestyle_settings.linesets) > 0:
        freestyle_settings.linesets.remove(freestyle_settings.linesets[0])
    
    # Create a new line set for edges
    lineset = freestyle_settings.linesets.new(name="EdgeLines")
    lineset.linestyle = bpy.data.linestyles.new(name="EdgeLineStyle")
    lineset.linestyle.color = (1.0, 1.0, 1.0)  # White lines for visibility
    lineset.linestyle.thickness = 1.0  # Fine line thickness
    
    # Enable edge types for better edge detection
    lineset.select_silhouette = True
    lineset.select_border = True
    lineset.select_crease = True
    lineset.select_edge_mark = True
    lineset.select_contour = True
    lineset.select_suggestive_contour = True
    lineset.select_material_boundary = True
    
    # Set alpha value for better visibility
    lineset.linestyle.alpha = 1.0
    
    # Ensure linestyle properties are set for maximum visibility
    lineset.linestyle.use_chaining = True
    lineset.linestyle.chaining = 'PLAIN'
    
    print("Freestyle setup complete for sketch generation with enhanced visibility")

def setup_compositor_force_prompting_style(scene_dir):
    """
    Setup compositor to save RGB, depth, and sketch with force-prompting naming convention
    """
    bpy.context.scene.use_nodes = True
    tree = bpy.context.scene.node_tree
    nodes = tree.nodes
    links = tree.links

    # Clear existing nodes
    for node in nodes:
        nodes.remove(node)

    # Create directories
    rgb_dir = os.path.join(scene_dir, "pngs")  # RGB frames go in pngs subdirectory
    depth_dir = os.path.join(scene_dir, "depth")
    sketch_dir = os.path.join(scene_dir, "sketch")
    
    os.makedirs(rgb_dir, exist_ok=True)
    os.makedirs(depth_dir, exist_ok=True)
    os.makedirs(sketch_dir, exist_ok=True)

    # Create render layers node
    render_layers_node = nodes.new(type='CompositorNodeRLayers')
    render_layers_node.location = (0, 0)

    # RGB output - regular Composite node (saves as frameXXXX.png)
    composite_node = nodes.new(type='CompositorNodeComposite')
    composite_node.location = (400, 0)
    links.new(render_layers_node.outputs['Image'], composite_node.inputs['Image'])
    
    # Set render output path for RGB frames
    bpy.context.scene.render.filepath = os.path.join(rgb_dir, "frame")
    
    # Depth output with normalization
    normalize_node = nodes.new('CompositorNodeNormalize')
    normalize_node.location = (200, -200)
    
    depth_output_node = nodes.new(type='CompositorNodeOutputFile')
    depth_output_node.base_path = depth_dir
    depth_output_node.file_slots[0].path = "depth_"
    depth_output_node.file_slots[0].format.file_format = 'PNG'
    depth_output_node.file_slots[0].use_node_format = False
    depth_output_node.format.file_format = 'PNG'
    depth_output_node.location = (400, -200)
    
    links.new(render_layers_node.outputs['Depth'], normalize_node.inputs[0])
    links.new(normalize_node.outputs[0], depth_output_node.inputs[0])

    # Sketch/Freestyle output - simplified for compatibility
    # Check if Freestyle pass is available
    if 'Freestyle' in render_layers_node.outputs:
        sketch_output_node = nodes.new(type='CompositorNodeOutputFile')
        sketch_output_node.base_path = sketch_dir
        sketch_output_node.file_slots[0].path = "sketch_"
        sketch_output_node.file_slots[0].format.file_format = 'PNG'
        sketch_output_node.file_slots[0].use_node_format = False
        sketch_output_node.format.file_format = 'PNG'
        sketch_output_node.location = (400, -400)
        
        # Direct connection without color ramp for compatibility
        links.new(render_layers_node.outputs['Freestyle'], sketch_output_node.inputs[0])
        
        print("Freestyle output connected for sketch generation")
    else:
        print("Warning: Freestyle output not available - sketch may be black")

def setup_render_settings(start_frame=1, end_frame=120, resolution=512):
    """
    Configure render settings
    """
    scene = bpy.context.scene
    
    # Frame range
    scene.frame_start = start_frame
    scene.frame_end = end_frame
    
    # Resolution
    scene.render.resolution_x = resolution
    scene.render.resolution_y = resolution
    scene.render.resolution_percentage = 100
    
    # Output format
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGB'
    
    # Use Cycles for better rendering (instead of Workbench)
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 32  # Lower samples for faster rendering
    scene.cycles.use_denoising = True
    
    # Setup freestyle for sketch generation
    setup_freestyle_for_sketch()

def clear_scene():
    """Clear all objects from the scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def create_floor(elasticity=0.8):
    """Create a floor plane with physics"""
    bpy.ops.mesh.primitive_plane_add(size=10, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.name = 'Floor'
    
    # Add collision
    bpy.ops.object.modifier_add(type='COLLISION')
    
    # Add rigid body
    bpy.ops.rigidbody.object_add()
    floor.rigid_body.type = 'PASSIVE'
    floor.rigid_body.restitution = elasticity
    floor.rigid_body.friction = 0.8  # Add friction for more realistic rolling
    
    return floor

def create_ball_with_physics(name, location, radius=0.5, ball_type='soccer', initial_velocity=(0, 0, 0), height_offset=0.0):
    """Create a ball with physics and textures"""
    # Create ball at specified height
    actual_location = (location[0], location[1], location[2] + height_offset)
    
    if USE_GPT4MOTION and ball_type:
        # Use GPT4Motion assets
        ball_assets = {
            'basketball': 'basketball.obj',
            'soccer': 'soccer_ball.obj', 
            'tennis': 'tennis_ball.obj',
            'bowling': 'bowling_ball.obj'
        }
        
        ball_file = ball_assets.get(ball_type, 'soccer_ball.obj')
        ball_path = os.path.join(ASSETS_PATH, ball_file)
        
        try:
            # Check if GPT4Motion functions are available
            if 'create_object_in_assets' in globals():
                ball = create_object_in_assets(
                    file_path=ball_path,
                    new_name=name,
                    position=actual_location,
                    max_dimension=radius * 2
                )
                
                if 'add_collision' in globals():
                    add_collision(ball)
                
                # Set mass based on ball type
                mass_map = {'basketball': 0.6, 'soccer': 0.43, 'tennis': 0.057, 'bowling': 7.2}
                mass = mass_map.get(ball_type, 0.6)
                
                if 'add_rigid_body' in globals():
                    add_rigid_body(ball, mass=mass, elasticity=0.825)
                
                # Apply initial velocity
                if initial_velocity != (0, 0, 0) and 'add_initial_velocity_for_rigid_body' in globals():
                    add_initial_velocity_for_rigid_body(ball, initial_velocity, (0, 0, 0))
                
                # Apply textures
                apply_ball_textures(ball)
                
                return ball
            else:
                print("GPT4Motion functions not available, using fallback")
                
        except Exception as e:
            print(f"Warning: Could not load {ball_file}, creating sphere instead: {e}")
    
    # Fallback to sphere creation
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=actual_location)
    ball = bpy.context.active_object
    ball.name = name
    
    # Add collision
    bpy.ops.object.modifier_add(type='COLLISION')
    
    # Add rigid body
    bpy.ops.rigidbody.object_add()
    ball.rigid_body.type = 'ACTIVE'
    ball.rigid_body.mass = 1.0
    ball.rigid_body.restitution = 0.9
    ball.rigid_body.collision_shape = 'SPHERE'
    ball.rigid_body.friction = 0.5
    
    # Set initial velocity if provided
    if initial_velocity != (0, 0, 0):
        ball.rigid_body.kinematic = True
        ball.keyframe_insert(data_path="rigid_body.kinematic", frame=1)
        ball.keyframe_insert(data_path='location', frame=1)
        
        # Move to frame 2 with velocity
        bpy.context.scene.frame_set(2)
        time_step = 1.0 / 24.0
        new_location = (
            actual_location[0] + initial_velocity[0] * time_step,
            actual_location[1] + initial_velocity[1] * time_step,
            actual_location[2] + initial_velocity[2] * time_step
        )
        ball.location = new_location
        ball.keyframe_insert(data_path='location', frame=2)
        
        # Disable kinematic to start physics
        ball.rigid_body.kinematic = False
        ball.keyframe_insert(data_path="rigid_body.kinematic", frame=2)
        
        bpy.context.scene.frame_set(1)
    
    # Apply textures
    apply_ball_textures(ball)
    
    return ball

def create_camera():
    """Create and position camera"""
    # Remove existing cameras
    for obj in bpy.data.objects:
        if obj.type == 'CAMERA':
            bpy.data.objects.remove(obj)
    
    # Create new camera
    camera_data = bpy.data.cameras.new(name='Camera')
    camera_object = bpy.data.objects.new('Camera', camera_data)
    bpy.context.collection.objects.link(camera_object)
    
    # Position camera for good view of rolling balls
    camera_object.location = (7, -7, 5)
    camera_object.rotation_euler = (math.radians(60), 0, math.radians(45))
    
    # Set as active camera
    bpy.context.scene.camera = camera_object
    
    return camera_object

def create_rolling_balls_scene_with_physics(params):
    """
    Create a scene with rolling balls based on physics parameters
    """
    # Clear scene
    clear_scene()
    
    # Create floor with elasticity
    floor = create_floor(elasticity=0.8)
    
    # Apply ground textures
    apply_ground_textures()
    
    # Extract physics parameters
    num_balls = params.get('num_balls', 3)
    ball_type = params.get('ball_type', 'soccer')
    force_angle = params.get('angle', 0)
    force_magnitude = params.get('force', 30)
    
    # Create main ball (the one that gets the force)
    main_ball_location = (0, 0, 2)  # Start at center
    main_ball = create_ball_with_physics(
        name="MainBall",
        location=main_ball_location,
        radius=0.4,
        ball_type=ball_type,
        height_offset=params.get('height_offset', 0)
    )
    
    # Apply force to main ball
    force_rad = math.radians(force_angle)
    force_x = force_magnitude * math.cos(force_rad) * 0.1  # Scale down
    force_y = force_magnitude * math.sin(force_rad) * 0.1
    force_z = 0
    
    initial_velocity = (force_x, force_y, force_z)
    
    # Set initial velocity for main ball
    main_ball.rigid_body.kinematic = True
    main_ball.keyframe_insert(data_path="rigid_body.kinematic", frame=1)
    main_ball.keyframe_insert(data_path='location', frame=1)
    
    bpy.context.scene.frame_set(2)
    time_step = 1.0 / 24.0
    new_location = (
        main_ball_location[0] + initial_velocity[0] * time_step,
        main_ball_location[1] + initial_velocity[1] * time_step,
        main_ball_location[2] + initial_velocity[2] * time_step
    )
    main_ball.location = new_location
    main_ball.keyframe_insert(data_path='location', frame=2)
    
    main_ball.rigid_body.kinematic = False
    main_ball.keyframe_insert(data_path="rigid_body.kinematic", frame=2)
    bpy.context.scene.frame_set(1)
    
    # Create additional balls (distractors)
    for i in range(1, num_balls):
        # Random position around the main ball
        angle = random.uniform(0, 2 * math.pi)
        distance = random.uniform(2, 4)
        x = distance * math.cos(angle)
        y = distance * math.sin(angle)
        z = random.uniform(1.5, 3)
        
        # Random ball type
        distractor_type = random.choice(['basketball', 'soccer', 'tennis', 'bowling'])
        
        # Some balls get random horizontal velocity
        if random.random() < 0.4:  # 40% chance
            vx = random.uniform(-2, 2)
            vy = random.uniform(-2, 2)
            vz = 0
            distractor_velocity = (vx, vy, vz)
        else:
            distractor_velocity = (0, 0, 0)
        
        create_ball_with_physics(
            name=f"Ball_{i}",
            location=(x, y, z),
            radius=random.uniform(0.3, 0.6),
            ball_type=distractor_type,
            initial_velocity=distractor_velocity,
            height_offset=random.uniform(-0.5, 0.5)
        )
    
    # Create camera
    create_camera()
    
    # Add lighting
    bpy.ops.object.light_add(type='SUN', location=(0, 0, 10))
    sun = bpy.context.active_object
    sun.data.energy = 3
    sun.data.angle = math.radians(15)  # Softer shadows
    
    # Add some fill light
    bpy.ops.object.light_add(type='AREA', location=(5, 5, 5))
    area_light = bpy.context.active_object
    area_light.data.energy = 200
    area_light.data.size = 5

def bake_physics():
    """Bake physics simulation"""
    bpy.ops.ptcache.free_bake_all()
    bpy.ops.ptcache.bake_all(bake=True)

def render_scene(scene_dir, frames=120):
    """Render the scene with RGB, depth, and sketch"""
    # Setup compositor
    setup_compositor_force_prompting_style(scene_dir)
    
    # Bake physics
    print("Baking physics simulation...")
    bake_physics()
    
    # Render frames
    scene = bpy.context.scene
    print(f"Rendering frames {scene.frame_start} to {frames}...")
    
    for frame in range(scene.frame_start, frames + 1):
        print(f"Rendering frame {frame}/{frames}")
        scene.frame_set(frame)
        
        # Update render filepath for each frame
        rgb_dir = os.path.join(scene_dir, "pngs")
        bpy.context.scene.render.filepath = os.path.join(rgb_dir, f"frame{frame:04d}")
        
        bpy.ops.render.render(write_still=True)

def generate_scene_name(params):
    """Generate scene directory name in force-prompting format"""
    angle = params.get('angle', random.uniform(0, 360))
    force = params.get('force', random.uniform(10, 60))
    coordx = params.get('coordx', random.randint(100, 600))
    coordy = params.get('coordy', random.randint(100, 400))
    pixangle = params.get('pixangle', random.uniform(0, 360))
    
    return f"angle_{angle:.1f}_force_{force:.2f}_coordx_{coordx}_coordy_{coordy}_pixangle_{pixangle:.1f}"

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Rolling balls renderer (force-prompting style)')
    parser.add_argument('--output_dir', type=str, required=True,
                        help='Base output directory')
    parser.add_argument('--scene_name', type=str, default=None,
                        help='Scene name (auto-generated if not provided)')
    parser.add_argument('--num_balls', type=int, default=3,
                        help='Number of balls')
    parser.add_argument('--ball_type', type=str, default='soccer',
                        help='Ball type (basketball/soccer/tennis/bowling)')
    parser.add_argument('--frames', type=int, default=120,
                        help='Number of frames to render')
    parser.add_argument('--resolution', type=int, default=512,
                        help='Resolution (square)')
    parser.add_argument('--seed', type=int, default=None,
                        help='Random seed')
    
    # Physics parameters
    parser.add_argument('--angle', type=float, default=None,
                        help='Force angle in degrees')
    parser.add_argument('--force', type=float, default=None,
                        help='Force magnitude')
    parser.add_argument('--coordx', type=int, default=None,
                        help='X coordinate (for naming)')
    parser.add_argument('--coordy', type=int, default=None,
                        help='Y coordinate (for naming)')
    parser.add_argument('--pixangle', type=float, default=None,
                        help='Pixel angle (for naming)')
    parser.add_argument('--height_offset', type=float, default=0,
                        help='Height offset for main ball')
    
    # Parse arguments
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    
    args = parser.parse_args(argv)
    
    # Set random seed
    if args.seed is not None:
        random.seed(args.seed)
    
    # Setup physics-based parameters
    params = {
        'num_balls': args.num_balls,
        'ball_type': args.ball_type,
        'angle': args.angle if args.angle is not None else random.uniform(0, 360),
        'force': args.force if args.force is not None else random.uniform(10, 60),
        'coordx': args.coordx if args.coordx is not None else random.randint(100, 600),
        'coordy': args.coordy if args.coordy is not None else random.randint(100, 400),
        'pixangle': args.pixangle if args.pixangle is not None else random.uniform(0, 360),
        'height_offset': args.height_offset
    }
    
    # Generate scene name if not provided
    if args.scene_name:
        scene_name = args.scene_name
    else:
        scene_name = generate_scene_name(params)
    
    # Full scene directory path
    scene_dir = os.path.join(args.output_dir, scene_name)
    os.makedirs(scene_dir, exist_ok=True)
    
    # Save params
    params_file = os.path.join(scene_dir, "params.json")
    with open(params_file, 'w') as f:
        json.dump(params, f, indent=2)
    
    # Setup render settings
    setup_render_settings(start_frame=1, end_frame=args.frames, resolution=args.resolution)
    
    # Create scene with physics
    print(f"Creating scene: {scene_name}")
    create_rolling_balls_scene_with_physics(params)
    
    # Render
    render_scene(scene_dir, args.frames)
    
    print(f"Rendering complete!")
    print(f"Scene directory: {scene_dir}")
    print(f"  - RGB frames: {scene_dir}/pngs/frameXXXX.png")
    print(f"  - Depth maps: {scene_dir}/depth/")
    print(f"  - Sketches: {scene_dir}/sketch/")
    print(f"  - Parameters: {scene_dir}/params.json")

if __name__ == "__main__":
    main() 