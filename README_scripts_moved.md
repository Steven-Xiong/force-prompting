# Scripts Moved to force-prompting

## What Changed

The depth and sketch generation scripts have been moved from the root `scripts/` directory to inside the `force-prompting/` project directory, and all paths have been updated to work when running from the `force-prompting` directory.

### Files Moved

**From:** `scripts/build_synthetic_datasets/poke_model_rolling_balls/`
**To:** `force-prompting/scripts/build_synthetic_datasets/poke_model_rolling_balls/`

Files moved:
- `rolling_balls_render_with_depth_sketch.py`
- `rolling_balls_render_enhanced.py`
- `rolling_balls_render_force_prompting_style.py`

### Scripts Updated

All shell scripts have been updated to work when run from within the `force-prompting` directory:
- `data_gen_with_depth_sketch.sh`
- `data_gen_enhanced.sh`
- `data_gen_force_prompting_style.sh`

### Path Updates

1. **Working Directory**: Scripts now expect to be run from within `force-prompting/`
   - **Old**: `cd "$(dirname "$0")/.."` (change to video_gen)
   - **New**: No directory change needed

2. **Blender Path**: 
   - **Old**: `/u/zhexiao/video_gen/GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender`
   - **New**: `GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender` (using soft link)

3. **Python Script Paths**:
   - **Old**: `force-prompting/scripts/build_synthetic_datasets/poke_model_rolling_balls/script.py`
   - **New**: `scripts/build_synthetic_datasets/poke_model_rolling_balls/script.py`

4. **Output Directories**:
   - **Old**: `force-prompting/scratch/rolling_balls/`
   - **New**: `scratch/rolling_balls/`

5. **GPT4Motion Paths in Python**: 
   - **Old**: `'../../../../../GPT4Motion/PhysicsGeneration'`
   - **New**: `'../../../GPT4Motion/PhysicsGeneration'` (using soft link in force-prompting)

## How to Test

Run the test script to verify everything works:
```bash
cd force-prompting
./test_moved_scripts.sh
```

This will create test outputs in `scratch/rolling_balls/test_moved_scripts/`

## Benefits of This Move

1. **Better Organization**: All force-prompting related scripts are now contained within the project
2. **Easier Distribution**: The entire force-prompting project is now self-contained
3. **No Root Directory Clutter**: Keeps the root video_gen directory cleaner
4. **Consistent Structure**: Follows the project's existing organization pattern
5. **Simpler Paths**: All paths are now relative to the force-prompting directory
6. **GPT4Motion Soft Link**: Uses a soft link to GPT4Motion within the project for easier access

## Usage

**Important**: All scripts must be run from within the `force-prompting` directory:

```bash
cd force-prompting
./data_gen_force_prompting_style.sh    # Recommended for production use
./data_gen_enhanced.sh                 # For advanced features with GPT4Motion assets
./data_gen_with_depth_sketch.sh        # Basic depth/sketch generation
```

The scripts automatically handle the path changes internally and will create outputs in the appropriate subdirectories. 