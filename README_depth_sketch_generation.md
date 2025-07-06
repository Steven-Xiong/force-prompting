# Force-Prompting Data Generation with Depth and Sketch

This README describes the new data generation scripts that create rolling balls animations with RGB, depth map, and sketch outputs.

## Overview

We have created three approaches for generating rolling balls data with additional modalities:

1. **Basic Approach** (`data_gen_with_depth_sketch.sh`) - A standalone implementation
2. **Enhanced Approach** (`data_gen_enhanced.sh`) - Uses GPT4Motion's BlenderTool utilities
3. **Force-Prompting Style** (`data_gen_force_prompting_style.sh`) - Matches original file structure exactly

All approaches generate:
- RGB frames (regular rendered images)
- Depth maps (normalized depth information)
- Sketch/Canny edges (using Blender's Freestyle)
- Binary masks (optional, in enhanced version)

## Scripts

### 1. Basic Implementation

**Script**: `force-prompting/data_gen_with_depth_sketch.sh`
**Python**: `scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_with_depth_sketch.py`

Features:
- Self-contained implementation
- Generates simple sphere-based rolling balls
- Outputs RGB, depth, and sketch to separate folders
- Compatible with system Blender installation

Usage:
```bash
cd /u/zhexiao/video_gen
./force-prompting/data_gen_with_depth_sketch.sh
```

### 2. Enhanced Implementation

**Script**: `force-prompting/data_gen_enhanced.sh`
**Python**: `scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_enhanced.py`

Features:
- Uses GPT4Motion's BlenderTool utilities
- Supports multiple ball types (basketball, soccer, tennis, bowling)
- Uses actual 3D ball models from GPT4Motion assets
- Includes physics simulation with initial velocities and rotations
- Optional wind forces for dynamic effects
- Generates metadata JSON for each scene

Usage:
```bash
cd /u/zhexiao/video_gen
./force-prompting/data_gen_enhanced.sh
```

### 3. Force-Prompting Style (Recommended for Compatibility)

**Script**: `force-prompting/data_gen_force_prompting_style.sh`
**Python**: `scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py`

Features:
- **Exactly matches original force-prompting file structure**
- RGB frames saved as `frameXXXX.png` in main directory
- Depth and sketch saved in subdirectories
- Directory names follow `angle_X_force_Y_coordx_Z_coordy_W_pixangle_V` format
- Generates `params.json` for each scene
- Optionally uses GPT4Motion assets if available

Usage:
```bash
cd /u/zhexiao/video_gen
./force-prompting/data_gen_force_prompting_style.sh
```

## Output Structure

### Force-Prompting Style (Original Format):
```
force-prompting/scratch/rolling_balls/depth_sketch/
└── angle_45.0_force_30.00_coordx_256_coordy_256_pixangle_45.0/
    ├── params.json        # Scene parameters
    ├── pngs/             # RGB frames
    │   ├── frame0001.png
    │   ├── frame0002.png
    │   └── ...
    ├── depth/            # Depth maps
    │   ├── depth_0001.png
    │   ├── depth_0002.png
    │   └── ...
    └── sketch/           # Edge detection sketches
        ├── sketch_0001.png
        ├── sketch_0002.png
        └── ...09_coordx_151_coordy_205_pixangle_999.9/
    └── ... (same structure)
```

### Enhanced Implementation:
```
/u/zhexiao/video_gen/force-prompting/scratch/rolling_balls/
├── enhanced_output/              # Raw PNG frames
│   ├── scene_0001_basketball_3balls/
│   │   ├── freestyle/           # RGB frames
│   │   ├── depth/              # Depth maps
│   │   ├── mask/               # Binary masks
│   │   └── metadata.json       # Scene metadata
│   └── ...
└── videos_enhanced/             # Converted MP4 videos
    ├── scene_0001_basketball_3balls.mp4       # RGB video
    ├── scene_0001_basketball_3balls_depth.mp4  # Depth video
    ├── scene_0001_basketball_3balls_mask.mp4   # Mask video
    └── ...
```

## Customization

### Modifying the Force-Prompting Style Script

You can customize the generation by editing the shell script parameters:

```bash
# Number of scenes to generate
NUM_SCENES=20

# Ball types to use
BALL_TYPES=("basketball" "soccer" "tennis" "bowling")

# Frame count (set in Python call)
--frames 120

# Resolution
--resolution 512
```

### Python Script Arguments

The force-prompting style script accepts these arguments:
- `--output_dir`: Base output directory
- `--scene_name`: Scene name (auto-generated if not provided)
- `--num_balls`: Number of balls to create (default: 3)
- `--ball_type`: Type of ball (basketball/soccer/tennis/bowling)
- `--frames`: Number of frames to render (default: 120)
- `--resolution`: Resolution in pixels (default: 512)
- `--seed`: Random seed for reproducibility
- `--angle`, `--force`, `--coordx`, `--coordy`, `--pixangle`: Force-prompting specific parameters

Example:
```bash
blender -b -P rolling_balls_render_force_prompting_style.py -- \
    --output_dir force-prompting/scratch/rolling_balls/pngs \
    --num_balls 3 \
    --ball_type basketball \
    --frames 120 \
    --angle 45.0 \
    --force 30.0 \
    --coordx 256 \
    --coordy 256 \
    --pixangle 45.0
```

## Integration with Original Pipeline

The force-prompting style script is designed to be a drop-in replacement for the original data generation:

1. Uses identical directory structure
2. Generates `frameXXXX.png` files like the original
3. Creates `params.json` with scene parameters
4. Compatible with existing training pipelines
5. Adds depth and sketch as optional subdirectories

All outputs are saved within the force-prompting project directory:
- PNGs: `/u/zhexiao/video_gen/force-prompting/scratch/rolling_balls/pngs/`
- Videos: `/u/zhexiao/video_gen/force-prompting/scratch/rolling_balls/videos/`
- CSVs: `/u/zhexiao/video_gen/force-prompting/datasets/point-force/train/`

## Dependencies

- Blender (uses GPT4Motion's Blender 4.4.3 installation)
- Python packages: opencv-python, numpy, pathlib
- GPT4Motion's BlenderTool (optional, for enhanced ball models)

## Notes

1. The force-prompting style script is recommended for maximum compatibility with existing pipelines
2. RGB frames are saved as `frameXXXX.png` matching the original format
3. Depth maps are normalized to 0-255 range for better visualization
4. Sketch/Freestyle outputs provide edge detection useful for training
5. Each scene is reproducible using the seed parameter
6. All outputs are stored within the force-prompting project directory structure

## Troubleshooting

If you encounter issues:

1. Ensure Blender path is correct in the shell scripts
2. Check that GPT4Motion's BlenderTool is accessible (for enhanced features)
3. Verify output directories have write permissions
4. For asset loading errors, the script falls back to simple spheres
5. Make sure you run scripts from the `/u/zhexiao/video_gen` directory
6. If RGB frames are missing, check the compositor setup in the Python script 


<!-- The scripts generate the following directory structure:
force-prompting/scratch/rolling_balls/depth_sketch/
└── angle_45.0_force_30.00_coordx_256_coordy_256_pixangle_45.0/
    ├── params.json        # Scene parameters
    ├── pngs/             # RGB frames
    │   ├── frame0001.png
    │   ├── frame0002.png
    │   └── ...
    ├── depth/            # Depth maps
    │   ├── depth_0001.png
    │   ├── depth_0002.png
    │   └── ...
    └── sketch/           # Edge detection sketches
        ├── sketch_0001.png
        ├── sketch_0002.png
        └── ... -->
```