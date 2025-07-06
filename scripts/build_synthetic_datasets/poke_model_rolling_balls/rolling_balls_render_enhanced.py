#!/usr/bin/env python3
"""
Enhanced rolling balls renderer using GPT4Motion's BlenderTool utils
Renders rolling balls animations with RGB, depth map, and sketch outputs
"""

import bpy
import os
import sys
import math
import random
import argparse
from pathlib import Path

# Add GPT4Motion BlenderTool to path
gpt4motion_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../GPT4Motion/PhysicsGeneration'))
sys.path.insert(0, gpt4motion_path)

from BlenderTool.utils import *

# Override ASSETS_PATH with absolute path
ASSETS_PATH = os.path.join(gpt4motion_path, 'BlenderTool/assets/')
print(f"Using assets path: {ASSETS_PATH}")

def create_rolling_balls_scene_enhanced(num_balls=3, ball_type='basketball'):
    """
    Create a scene with rolling balls using GPT4Motion utils
    
    Args:
        num_balls: Number of balls to create
        ball_type: Type of ball ('basketball', 'soccer', 'tennis', etc.)
    """
    # Clear scene
    clear_scene()
    
    # Create floor with elasticity for bouncing
    create_floor(elasticity=0.8)
    
    # Ball asset mapping
    ball_assets = {
        'basketball': 'basketball.obj',
        'soccer': 'soccer_ball.obj',
        'tennis': 'tennis_ball.obj',
        'bowling': 'bowling_ball.obj'
    }
    
    # Ball size mapping (in meters)
    ball_sizes = {
        'basketball': 0.24,
        'soccer': 0.22,
        'tennis': 0.067,
        'bowling': 0.217
    }
    
    # Get ball file and size
    ball_file = ball_assets.get(ball_type, 'basketball.obj')
    ball_size = ball_sizes.get(ball_type, 0.24)
    
    # Create balls with random positions and velocities
    for i in range(num_balls):
        # Random position
        x = random.uniform(-2.5, 2.5)
        y = random.uniform(-2.5, 2.5)
        z = random.uniform(2, 4)
        position = (x, y, z)
        
        # Random initial velocity
        vx = random.uniform(-5, 5)
        vy = random.uniform(-5, 5)
        vz = random.uniform(-2, 2)
        initial_velocity = (vx, vy, vz)
        
        # Random initial rotation (in degrees)
        rx = random.uniform(0, 360)
        ry = random.uniform(0, 360)
        rz = random.uniform(0, 360)
        initial_rotation = (rx, ry, rz)
        
        # Create ball using GPT4Motion utils
        try:
            ball_path = ASSETS_PATH + ball_file
            ball = create_object_in_assets(
                file_path=ball_path,
                new_name=f"Ball_{i}",
                position=position,
                max_dimension=ball_size * random.uniform(0.8, 1.2)  # Slight size variation
            )
            
            # Add physics
            add_collision(ball)
            add_rigid_body(
                ball,
                mass=0.6 * (ball_size / 0.24),  # Mass proportional to size
                elasticity=0.825,
                rigid_body_type='ACTIVE'
            )
            
            # Add initial velocity and rotation
            add_initial_velocity_for_rigid_body(ball, initial_velocity, initial_rotation)
            
        except Exception as e:
            print(f"Warning: Could not load {ball_file}, creating sphere instead")
            # Fallback to simple sphere
            bpy.ops.mesh.primitive_uv_sphere_add(
                radius=ball_size/2,
                location=position
            )
            ball = bpy.context.active_object
            ball.name = f"Ball_{i}"
            add_collision(ball)
            add_rigid_body(ball, mass=0.6, elasticity=0.825)
            add_initial_velocity_for_rigid_body(ball, initial_velocity, initial_rotation)
    
    # Create camera using GPT4Motion default position
    create_camera()
    
    # Add wind force for more dynamic motion (optional)
    if random.random() > 0.7:  # 30% chance of wind
        wind_strength = random.uniform(500, 2000)
        wind_angle = random.uniform(0, 360)
        add_wind_force(
            direction=(0, math.radians(wind_angle), 0),
            strength=wind_strength
        )

def setup_enhanced_render_settings(output_path, start_frame=0, end_frame=120):
    """
    Setup render settings using GPT4Motion's approach
    """
    # Use GPT4Motion's render settings
    set_render_settings(start_frame, end_frame, output_path)
    
    # Setup compositor for RGB, depth, and sketch
    setup_compositor(output_path)
    
    # Additional settings for better quality
    bpy.context.scene.render.resolution_x = 512
    bpy.context.scene.render.resolution_y = 512
    bpy.context.scene.render.resolution_percentage = 100

def render_with_all_outputs(output_base_path):
    """
    Render animation with RGB, depth, and sketch outputs
    """
    # Create directories
    os.makedirs(output_base_path, exist_ok=True)
    
    # Setup render settings
    setup_enhanced_render_settings(output_base_path)
    
    # Bake physics
    print("Baking physics simulation...")
    bake_physics()
    
    # Render animation
    print("Rendering animation with RGB, depth, and sketch...")
    render_animation()
    
    # Also render mask (optional)
    print("Rendering mask...")
    rerender_for_mask(output_base_path)

def main():
    """Main function with argument parsing"""
    parser = argparse.ArgumentParser(description='Enhanced rolling balls renderer')
    parser.add_argument('--output_dir', type=str, required=True,
                        help='Output directory for rendered frames')
    parser.add_argument('--num_balls', type=int, default=3,
                        help='Number of balls to create')
    parser.add_argument('--ball_type', type=str, default='basketball',
                        choices=['basketball', 'soccer', 'tennis', 'bowling'],
                        help='Type of ball to use')
    parser.add_argument('--frames', type=int, default=120,
                        help='Number of frames to render')
    parser.add_argument('--seed', type=int, default=None,
                        help='Random seed for reproducibility')
    
    # Parse arguments (skip blender args)
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    
    args = parser.parse_args(argv)
    
    # Set random seed if provided
    if args.seed is not None:
        random.seed(args.seed)
    
    # Create scene
    print(f"Creating scene with {args.num_balls} {args.ball_type}s...")
    create_rolling_balls_scene_enhanced(
        num_balls=args.num_balls,
        ball_type=args.ball_type
    )
    
    # Update frame range
    bpy.context.scene.frame_end = args.frames
    
    # Render
    render_with_all_outputs(args.output_dir)
    
    print(f"Rendering complete! Output saved to: {args.output_dir}")
    print(f"  - RGB frames: {args.output_dir}/freestyle/")
    print(f"  - Depth maps: {args.output_dir}/depth/")
    print(f"  - Sketches: {args.output_dir}/freestyle/")
    print(f"  - Masks: {args.output_dir}/mask/")

if __name__ == "__main__":
    main() 