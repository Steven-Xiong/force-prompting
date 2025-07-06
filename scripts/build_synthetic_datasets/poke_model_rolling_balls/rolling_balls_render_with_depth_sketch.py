#!/usr/bin/env python3
"""
Rolling balls renderer with depth and sketch output
This script renders rolling balls animations with RGB, depth map, and sketch outputs
"""

import bpy
import os
import sys
import math
import random
import argparse
from pathlib import Path

# This script is self-contained and doesn't require external imports

def setup_compositor_with_depth_sketch(output_base_path):
    """
    Setup compositor nodes for RGB, depth, and sketch (freestyle) output
    Based on GPT4Motion's setup_compositor function
    """
    bpy.context.scene.use_nodes = True
    tree = bpy.context.scene.node_tree
    nodes = tree.nodes
    links = tree.links

    # Clear existing nodes
    for node in nodes:
        nodes.remove(node)

    # Create render layers node
    render_layers_node = nodes.new(type='CompositorNodeRLayers')
    render_layers_node.location = (0, 0)

    # RGB output - File Output for regular frames
    rgb_output_node = nodes.new(type='CompositorNodeOutputFile')
    rgb_output_node.base_path = os.path.join(output_base_path, "rgb")
    rgb_output_node.file_slots[0].path = "frame_"
    rgb_output_node.file_slots[0].format.file_format = 'PNG'
    rgb_output_node.location = (300, 200)
    os.makedirs(rgb_output_node.base_path, exist_ok=True)

    # Depth output with normalization
    normalize_node = nodes.new('CompositorNodeNormalize')
    normalize_node.location = (200, -100)
    
    depth_output_node = nodes.new(type='CompositorNodeOutputFile')
    depth_output_node.base_path = os.path.join(output_base_path, "depth")
    depth_output_node.file_slots[0].path = "depth_"
    depth_output_node.file_slots[0].format.file_format = 'PNG'
    depth_output_node.location = (400, -100)
    os.makedirs(depth_output_node.base_path, exist_ok=True)

    # Sketch/Canny output (Freestyle)
    sketch_output_node = nodes.new(type='CompositorNodeOutputFile')
    sketch_output_node.base_path = os.path.join(output_base_path, "sketch")
    sketch_output_node.file_slots[0].path = "sketch_"
    sketch_output_node.file_slots[0].format.file_format = 'PNG'
    sketch_output_node.location = (300, -300)
    os.makedirs(sketch_output_node.base_path, exist_ok=True)

    # Link nodes
    links.new(render_layers_node.outputs['Image'], rgb_output_node.inputs[0])
    links.new(render_layers_node.outputs['Depth'], normalize_node.inputs[0])
    links.new(normalize_node.outputs[0], depth_output_node.inputs[0])
    links.new(render_layers_node.outputs['Freestyle'], sketch_output_node.inputs[0])

def setup_render_settings(start_frame, end_frame, resolution_x=512, resolution_y=512):
    """
    Configure render settings for the scene
    """
    scene = bpy.context.scene
    
    # Frame range
    scene.frame_start = start_frame
    scene.frame_end = end_frame
    
    # Resolution
    scene.render.resolution_x = resolution_x
    scene.render.resolution_y = resolution_y
    scene.render.resolution_percentage = 100
    
    # Enable Freestyle for sketch/edge detection
    scene.render.use_freestyle = True
    scene.render.line_thickness_mode = 'ABSOLUTE'
    scene.render.line_thickness = 0.75
    
    # Enable Z pass for depth
    view_layer = scene.view_layers["ViewLayer"]
    view_layer.use_pass_z = True
    view_layer.freestyle_settings.as_render_pass = True
    
    # Use Workbench or Eevee for faster rendering
    scene.render.engine = 'BLENDER_WORKBENCH'

def clear_scene():
    """Clear all objects from the scene"""
    bpy.ops.object.select_all(action='SELECT')
    bpy.ops.object.delete()

def create_floor():
    """Create a floor plane with physics"""
    bpy.ops.mesh.primitive_plane_add(size=10, location=(0, 0, 0))
    floor = bpy.context.active_object
    floor.name = 'Floor'
    
    # Add collision
    bpy.ops.object.modifier_add(type='COLLISION')
    
    # Add rigid body
    bpy.ops.rigidbody.object_add()
    floor.rigid_body.type = 'PASSIVE'
    floor.rigid_body.restitution = 0.8
    
    return floor

def create_ball(name, location, radius=0.5, initial_velocity=(0, 0, 0)):
    """Create a ball with physics"""
    bpy.ops.mesh.primitive_uv_sphere_add(radius=radius, location=location)
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
    
    # Set initial velocity if provided
    if initial_velocity != (0, 0, 0):
        ball.rigid_body.kinematic = True
        ball.keyframe_insert(data_path="rigid_body.kinematic", frame=1)
        ball.keyframe_insert(data_path='location', frame=1)
        
        # Move to frame 2 with velocity
        bpy.context.scene.frame_set(2)
        time_step = 1.0 / 24.0  # Assuming 24 fps
        new_location = (
            location[0] + initial_velocity[0] * time_step,
            location[1] + initial_velocity[1] * time_step,
            location[2] + initial_velocity[2] * time_step
        )
        ball.location = new_location
        ball.keyframe_insert(data_path='location', frame=2)
        
        # Disable kinematic to start physics
        ball.rigid_body.kinematic = False
        ball.keyframe_insert(data_path="rigid_body.kinematic", frame=2)
        
        bpy.context.scene.frame_set(1)
    
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

def create_rolling_balls_scene(num_balls=3):
    """Create a scene with rolling balls"""
    # Clear scene
    clear_scene()
    
    # Create floor
    create_floor()
    
    # Create balls with random positions and velocities
    for i in range(num_balls):
        x = random.uniform(-2, 2)
        y = random.uniform(-2, 2)
        z = random.uniform(2, 4)
        
        vx = random.uniform(-3, 3)
        vy = random.uniform(-3, 3)
        vz = 0
        
        radius = random.uniform(0.3, 0.7)
        
        create_ball(
            name=f"Ball_{i}",
            location=(x, y, z),
            radius=radius,
            initial_velocity=(vx, vy, vz)
        )
    
    # Create camera
    create_camera()
    
    # Add some lighting
    bpy.ops.object.light_add(type='SUN', location=(0, 0, 10))
    sun = bpy.context.active_object
    sun.data.energy = 2

def bake_physics():
    """Bake physics simulation"""
    bpy.ops.ptcache.free_bake_all()
    bpy.ops.ptcache.bake_all(bake=True)

def render_animation(output_path):
    """Render the animation"""
    scene = bpy.context.scene
    
    # Create output directory structure
    os.makedirs(output_path, exist_ok=True)
    
    # Setup compositor for multi-output
    setup_compositor_with_depth_sketch(output_path)
    
    # Bake physics
    print("Baking physics simulation...")
    bake_physics()
    
    # Render animation
    print(f"Rendering frames {scene.frame_start} to {scene.frame_end}...")
    for frame in range(scene.frame_start, scene.frame_end + 1):
        print(f"Rendering frame {frame}/{scene.frame_end}")
        scene.frame_set(frame)
        bpy.ops.render.render(write_still=True)

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='Render rolling balls with depth and sketch')
    parser.add_argument('--output_dir', type=str, default='scratch/rolling_balls/multi_output',
                        help='Output directory for rendered frames')
    parser.add_argument('--num_balls', type=int, default=3,
                        help='Number of balls to create')
    parser.add_argument('--frames', type=int, default=120,
                        help='Number of frames to render')
    parser.add_argument('--resolution', type=int, default=512,
                        help='Resolution (square)')
    
    # Parse arguments (skip blender args)
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    
    args = parser.parse_args(argv)
    
    # Setup render settings
    setup_render_settings(
        start_frame=1,
        end_frame=args.frames,
        resolution_x=args.resolution,
        resolution_y=args.resolution
    )
    
    # Create scene
    create_rolling_balls_scene(num_balls=args.num_balls)
    
    # Render
    render_animation(args.output_dir)
    
    print(f"Rendering complete! Output saved to: {args.output_dir}")
    print(f"  - RGB frames: {args.output_dir}/rgb/")
    print(f"  - Depth maps: {args.output_dir}/depth/")
    print(f"  - Sketches: {args.output_dir}/sketch/")

if __name__ == "__main__":
    main() 