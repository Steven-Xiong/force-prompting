# Enhanced Force-Prompting Data Generation with Physics Control

## Overview

This enhanced version of the force-prompting data generation system addresses the three main issues:

1. ✅ **Fixed sketch rendering** - Sketch images are no longer all black
2. ✅ **Added texture support** - Balls now have realistic textures like the original code
3. ✅ **Implemented physics-based control** - Real physical meaning behind parameters

## Key Improvements

### 1. Realistic Physics Control

The new system generates physically meaningful parameters:

- **Force magnitude** is calculated based on ball mass (heavier balls need more force)
- **Force angles** are realistic (-30° to +30° from horizontal)
- **Starting heights** range from ground level to waist high (0-1 meters)
- **Ball counts** are realistic (fewer heavy balls, more light balls)
- **Lateral motion** is randomly added to 40% of distractor balls

### 2. Enhanced Texture System

- **Ball textures** from original `rolling_balls.py` are fully integrated
- **Ground textures** support different surface types (grass, concrete, dirt, wood, carpet)
- **Material variation** with random hue/saturation shifts
- **Surface-appropriate physics** (friction, bounce)

### 3. Fixed Sketch Generation

- **Proper Freestyle setup** with configured line sets
- **Enhanced edge detection** with silhouette, border, and crease lines
- **Color ramp processing** to enhance sketch contrast
- **Better rendering engine** (Cycles instead of Workbench) for quality

### 4. Comprehensive Metadata

Each scene includes:
- `params.json` - Basic force-prompting compatible parameters
- `physics_metadata.json` - Detailed physics information
- `{scene}_metadata.json` - Combined metadata for videos

## File Structure

### Updated Scripts

1. **`rolling_balls_render_force_prompting_style.py`** (Enhanced)
   - Added texture support from original `rolling_balls.py`
   - Fixed Freestyle sketch rendering
   - Implemented physics-based ball creation
   - Added height control and lateral motion

2. **`data_gen_force_prompting_style.sh`** (Enhanced)
   - Physics-based parameter generation
   - Realistic force/mass relationships
   - Surface type variation
   - Comprehensive statistics and metadata

3. **`test_enhanced_rendering.sh`** (New)
   - Single scene test with quality analysis
   - Checks RGB, depth, and sketch quality
   - Verifies texture and motion

## Usage

### Quick Test (Recommended First)

```bash
# Activate the diffusion-pipe environment
conda activate diffusion-pipe

# Run a single test scene
./test_enhanced_rendering.sh
```

This will:
- Generate one test scene with known parameters
- Check RGB, depth, and sketch quality
- Analyze texture and motion
- Create a test video

### Full Dataset Generation

```bash
# Generate 50 enhanced scenes
./data_gen_force_prompting_style.sh
```

This will:
- Generate 50 scenes with physics-based parameters
- Create RGB, depth, and sketch outputs
- Apply realistic textures and lighting
- Save comprehensive metadata
- Convert to videos with statistics

### Custom Parameters

You can also run individual scenes with specific parameters:

```bash
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
    --output_dir scratch/rolling_balls/custom \
    --scene_name "custom_test" \
    --num_balls 4 \
    --ball_type basketball \
    --frames 120 \
    --resolution 512 \
    --angle 25.0 \
    --force 30.5 \
    --height_offset 0.5 \
    --seed 42
```

## Output Structure

```
scratch/rolling_balls/depth_sketch/
└── angle_15.0_force_25.50_coordx_300_coordy_250_pixangle_18.3/
    ├── pngs/                       # RGB frames
    │   ├── frame0001.png
    │   ├── frame0002.png
    │   └── ...
    ├── depth/                      # Depth maps
    │   ├── depth_0001.png
    │   ├── depth_0002.png  
    │   └── ...
    ├── sketch/                     # Edge detection sketches
    │   ├── sketch_0001.png
    │   ├── sketch_0002.png
    │   └── ...
    ├── params.json                 # Basic parameters (force-prompting compatible)
    └── physics_metadata.json       # Enhanced physics data
```

### Videos Directory

```
scratch/rolling_balls/videos/
├── angle_15.0_force_25.50_coordx_300_coordy_250_pixangle_18.3.mp4
├── angle_15.0_force_25.50_coordx_300_coordy_250_pixangle_18.3_depth.mp4
├── angle_15.0_force_25.50_coordx_300_coordy_250_pixangle_18.3_sketch.mp4
└── angle_15.0_force_25.50_coordx_300_coordy_250_pixangle_18.3_metadata.json
```

## Physics Metadata Example

```json
{
    "ball_type": "basketball",
    "ball_mass_kg": 0.6,
    "ball_diameter_m": 0.24,
    "force_magnitude_n": 25.5,
    "force_angle_degrees": 15.0,
    "starting_height_m": 0.75,
    "surface_type": "concrete",
    "lateral_motion_enabled": 1,
    "physics_coordinates": {
        "x_meters": 0.44,
        "y_meters": -0.06
    },
    "scene_description": "Ball rolling simulation with realistic physics: basketball ball with mass 0.6kg receives 25.5N force at 15.0° angle from height 0.75m on concrete surface"
}
```

## Enhanced CSV Output

The generated CSV includes all metadata fields:

- Basic force-prompting parameters (angle, force, coordx, coordy, pixangle)
- Physics parameters (ball_mass_kg, force_magnitude_n, starting_height_m)
- Scene information (ball_type, surface_type, lateral_motion_enabled)
- File paths and quality indicators

## Troubleshooting

### Sketch Images Still Black

1. Check if Freestyle is properly enabled:
   ```bash
   # Look for "Freestyle setup complete" in the output
   ```

2. Verify Cycles renderer is working:
   ```bash
   # Should see "Use Cycles for better rendering" message
   ```

### Missing Textures

1. Ensure texture directories exist:
   ```bash
   ls scripts/build_synthetic_datasets/poke_model_rolling_balls/football_textures/
   ls scripts/build_synthetic_datasets/poke_model_rolling_balls/ground_textures/
   ```

2. Check texture loading messages in Blender output

### Physics Not Realistic

1. Verify physics metadata is being generated:
   ```bash
   # Check for physics_metadata.json files
   find scratch/rolling_balls/depth_sketch/ -name "physics_metadata.json"
   ```

2. Review force calculations in the shell script

## Environment Requirements

- **Conda environment**: `diffusion-pipe`
- **Blender**: GPT4Motion's Blender 4.4.3 installation
- **Python packages**: OpenCV, NumPy, JSON
- **System tools**: bc (for floating-point calculations)

## Performance Notes

- **Rendering time**: ~2-3 minutes per scene (120 frames at 512x512)
- **Storage**: ~100MB per scene (RGB + depth + sketch)
- **Memory**: ~4GB RAM recommended for Blender
- **Cycles samples**: Set to 32 for balance of quality/speed

## Next Steps

1. **Test first**: Always run `./test_enhanced_rendering.sh` to verify setup
2. **Small batch**: Try 5-10 scenes first to check quality
3. **Full dataset**: Run the complete 50-scene generation
4. **Quality review**: Check statistics and sample videos
5. **Training**: Use the enhanced CSV for model training 