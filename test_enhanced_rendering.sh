#!/bin/bash

# Test script for enhanced force-prompting style rendering
echo "Testing enhanced force-prompting style rendering..."
echo "This will generate ONE test scene to verify all improvements"

# Stay in force-prompting directory
echo "Working directory: $(pwd)"

# Use GPT4Motion's Blender
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Test output directory
TEST_OUTPUT_DIR="scratch/rolling_balls/test_enhanced"
mkdir -p $TEST_OUTPUT_DIR

echo "==========================================="
echo "Running enhanced test render..."

# Test with specific physics parameters
BALL_TYPE="basketball"
FORCE_MAGNITUDE="25.5"
FORCE_ANGLE="15.0"
COORDX="300"
COORDY="250"
PIXANGLE="18.3"
HEIGHT_OFFSET="0.75"
NUM_BALLS="3"

echo "Test parameters:"
echo "  Ball type: $BALL_TYPE"
echo "  Force: ${FORCE_MAGNITUDE}N at ${FORCE_ANGLE}°"
echo "  Starting height: ${HEIGHT_OFFSET}m"
echo "  Number of balls: $NUM_BALLS"

SCENE_NAME="angle_${FORCE_ANGLE}_force_${FORCE_MAGNITUDE}_coordx_${COORDX}_coordy_${COORDY}_pixangle_${PIXANGLE}"

$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
    --output_dir $TEST_OUTPUT_DIR \
    --scene_name $SCENE_NAME \
    --num_balls $NUM_BALLS \
    --ball_type $BALL_TYPE \
    --frames 10 \
    --resolution 512 \
    --angle $FORCE_ANGLE \
    --force $FORCE_MAGNITUDE \
    --coordx $COORDX \
    --coordy $COORDY \
    --pixangle $PIXANGLE \
    --height_offset $HEIGHT_OFFSET \
    --seed 42

echo "==========================================="
echo "Checking enhanced output files..."

# Full scene directory path
SCENE_DIR="$TEST_OUTPUT_DIR/$SCENE_NAME"

# Check RGB frames
if [ -d "$SCENE_DIR/pngs" ]; then
    echo "✓ RGB frames directory found"
    RGB_COUNT=$(ls -1 $SCENE_DIR/pngs/frame*.png 2>/dev/null | wc -l)
    echo "  Found $RGB_COUNT RGB frames"
    
    # Check first frame for texture
    if [ $RGB_COUNT -gt 0 ]; then
        FIRST_FRAME=$(ls $SCENE_DIR/pngs/frame*.png | head -1)
        if [ -f "$FIRST_FRAME" ]; then
            echo "  ✓ First frame exists: $(basename $FIRST_FRAME)"
        fi
    fi
else
    echo "✗ RGB frames directory not found"
fi

# Check depth maps
if [ -d "$SCENE_DIR/depth" ]; then
    echo "✓ Depth maps directory found"
    DEPTH_COUNT=$(ls -1 $SCENE_DIR/depth/depth_*.png 2>/dev/null | wc -l)
    echo "  Found $DEPTH_COUNT depth maps"
    
    if [ $DEPTH_COUNT -gt 0 ]; then
        FIRST_DEPTH=$(ls $SCENE_DIR/depth/depth_*.png | head -1)
        if [ -f "$FIRST_DEPTH" ]; then
            echo "  ✓ First depth map exists: $(basename $FIRST_DEPTH)"
        fi
    fi
else
    echo "✗ Depth maps directory not found"
fi

# Check sketch maps
if [ -d "$SCENE_DIR/sketch" ]; then
    echo "✓ Sketch directory found"
    SKETCH_COUNT=$(ls -1 $SCENE_DIR/sketch/sketch_*.png 2>/dev/null | wc -l)
    echo "  Found $SKETCH_COUNT sketch maps"
    
    if [ $SKETCH_COUNT -gt 0 ]; then
        FIRST_SKETCH=$(ls $SCENE_DIR/sketch/sketch_*.png | head -1)
        if [ -f "$FIRST_SKETCH" ]; then
            echo "  ✓ First sketch exists: $(basename $FIRST_SKETCH)"
            
            # Check if sketch is not all black
            python3 << EOF
import cv2
import numpy as np

sketch_path = "$FIRST_SKETCH"
try:
    img = cv2.imread(sketch_path, cv2.IMREAD_GRAYSCALE)
    if img is not None:
        mean_brightness = np.mean(img)
        max_brightness = np.max(img)
        print(f"  Sketch brightness - Mean: {mean_brightness:.1f}, Max: {max_brightness:.1f}")
        if max_brightness > 50:  # Not completely black
            print("  ✓ Sketch appears to have content (not all black)")
        else:
            print("  ⚠ Sketch appears to be mostly black")
    else:
        print("  ✗ Could not read sketch file")
except Exception as e:
    print(f"  ✗ Error checking sketch: {e}")
EOF
        fi
    fi
else
    echo "✗ Sketch directory not found"
fi

# Check parameters
if [ -f "$SCENE_DIR/params.json" ]; then
    echo "✓ Basic parameters file found"
    echo "  Content preview:"
    head -5 "$SCENE_DIR/params.json" | sed 's/^/    /'
else
    echo "✗ Basic parameters file not found"
fi

# Check physics metadata (if created)
if [ -f "$SCENE_DIR/physics_metadata.json" ]; then
    echo "✓ Physics metadata file found"
    echo "  Content preview:"
    head -8 "$SCENE_DIR/physics_metadata.json" | sed 's/^/    /'
else
    echo "! Physics metadata file not found (this is created by the shell script)"
fi

echo "==========================================="
echo "Creating test video and checking quality..."

# Convert to video
python3 << 'EOF'
import cv2
import numpy as np
from pathlib import Path

test_dir = Path("scratch/rolling_balls/test_enhanced").glob("angle_*")
scene_dirs = list(test_dir)

if not scene_dirs:
    print("✗ No test scene directories found!")
    exit(1)

scene_dir = scene_dirs[0]
print(f"Processing scene: {scene_dir.name}")

# Check RGB frames
rgb_dir = scene_dir / "pngs"
rgb_frames = sorted(rgb_dir.glob("frame*.png"))

if rgb_frames:
    first_frame = cv2.imread(str(rgb_frames[0]))
    if first_frame is not None:
        height, width = first_frame.shape[:2]
        
        # Create video
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        video_path = f"scratch/rolling_balls/test_enhanced/test_enhanced.mp4"
        out = cv2.VideoWriter(video_path, fourcc, 24.0, (width, height))
        
        for frame_path in rgb_frames:
            frame = cv2.imread(str(frame_path))
            if frame is not None:
                out.write(frame)
        
        out.release()
        print(f"✓ Test video created: {video_path}")
        
        # Quality analysis
        print("\nQuality Analysis:")
        print(f"  Resolution: {width}x{height}")
        print(f"  Frame count: {len(rgb_frames)}")
        
        # Analyze first frame
        first_gray = cv2.cvtColor(first_frame, cv2.COLOR_BGR2GRAY)
        mean_brightness = np.mean(first_gray)
        std_brightness = np.std(first_gray)
        
        print(f"  Brightness - Mean: {mean_brightness:.1f}, Std: {std_brightness:.1f}")
        
        if mean_brightness > 20 and std_brightness > 10:
            print("  ✓ Frame appears to have good contrast and lighting")
        else:
            print("  ⚠ Frame may be too dark or lack contrast")
            
        # Check for motion between frames
        if len(rgb_frames) > 1:
            last_frame = cv2.imread(str(rgb_frames[-1]))
            if last_frame is not None:
                last_gray = cv2.cvtColor(last_frame, cv2.COLOR_BGR2GRAY)
                diff = cv2.absdiff(first_gray, last_gray)
                motion_amount = np.mean(diff)
                print(f"  Motion amount: {motion_amount:.1f}")
                
                if motion_amount > 5:
                    print("  ✓ Significant motion detected between first and last frame")
                else:
                    print("  ⚠ Limited motion detected - balls may not be moving much")
    else:
        print("✗ Could not read first frame")
else:
    print("✗ No RGB frames found")

# Check depth frames
depth_dir = scene_dir / "depth"
depth_frames = sorted(depth_dir.glob("depth_*.png"))

if depth_frames:
    print(f"\nDepth Analysis:")
    print(f"  Depth frame count: {len(depth_frames)}")
    
    first_depth = cv2.imread(str(depth_frames[0]), cv2.IMREAD_GRAYSCALE)
    if first_depth is not None:
        depth_range = np.max(first_depth) - np.min(first_depth)
        print(f"  Depth range: {depth_range} (0-255 scale)")
        
        if depth_range > 50:
            print("  ✓ Good depth variation detected")
        else:
            print("  ⚠ Limited depth variation")

# Check sketch frames
sketch_dir = scene_dir / "sketch"
sketch_frames = sorted(sketch_dir.glob("sketch_*.png"))

if sketch_frames:
    print(f"\nSketch Analysis:")
    print(f"  Sketch frame count: {len(sketch_frames)}")
    
    first_sketch = cv2.imread(str(sketch_frames[0]), cv2.IMREAD_GRAYSCALE)
    if first_sketch is not None:
        non_black_pixels = np.sum(first_sketch > 10)
        total_pixels = first_sketch.shape[0] * first_sketch.shape[1]
        coverage = (non_black_pixels / total_pixels) * 100
        
        print(f"  Edge coverage: {coverage:.1f}% of pixels")
        
        if coverage > 1:
            print("  ✓ Sketch lines detected")
        else:
            print("  ✗ Sketch appears to be mostly black - Freestyle may not be working")

EOF

echo "==========================================="
echo "Enhanced test complete!"
echo ""
echo "Test Results Summary:"
echo "  - Scene directory: $SCENE_DIR"
echo "  - Test video: scratch/rolling_balls/test_enhanced/test_enhanced.mp4"
echo ""
echo "What to check:"
echo "1. RGB frames should have textured balls and realistic lighting"
echo "2. Depth maps should show clear depth gradients"
echo "3. Sketch frames should have visible edge lines (not all black)"
echo "4. Motion should be realistic based on physics parameters"
echo ""
echo "If everything looks good, run the full generation with:"
echo "  ./data_gen_force_prompting_style.sh" 