#!/bin/bash

# 测试修复后的主脚本 - 生成5个场景
echo "Testing FIXED main script with 5 scenes..."

# 基本设置
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"
OUTPUT_BASE_DIR="scratch/rolling_balls/fixed_test"
mkdir -p $OUTPUT_BASE_DIR

# Ball types to use with their physical properties
declare -A BALL_MASSES=(
    ["basketball"]=0.6
    ["soccer"]=0.43
    ["tennis"]=0.057
    ["bowling"]=7.2
)

declare -A BALL_SIZES=(
    ["basketball"]=0.24
    ["soccer"]=0.22
    ["tennis"]=0.067
    ["bowling"]=0.217
)

# Ground surface types that affect friction and bounce
SURFACE_TYPES=("grass" "concrete" "dirt" "wood" "carpet")

# Function to generate physically meaningful parameters
generate_physics_params() {
    local scene_id=$1
    
    # Ball type affects all other parameters
    local ball_types=("basketball" "soccer" "tennis" "bowling")
    local main_ball_type=${ball_types[$((RANDOM % ${#ball_types[@]}))]}
    
    # Force magnitude based on ball mass (heavier balls need more force)
    local random_multiplier=$((15 + RANDOM % 40))
    local base_force=$(echo "scale=2; ${BALL_MASSES[$main_ball_type]} * $random_multiplier" | bc)
    
    # Angle: realistic throwing/kicking angles (mostly horizontal with some variation)
    local angle_offset=$((RANDOM % 60))
    local force_angle=$(echo "scale=1; $angle_offset - 30" | bc)  # -30 to +30 degrees from horizontal
    
    # Height: realistic starting heights (on ground to waist high)
    local height_rand=$((RANDOM % 100))
    local height_offset=$(echo "scale=2; $height_rand / 100" | bc)  # 0.0 to 1.0 meters
    
    # Number of balls: fewer for heavier balls (more realistic)
    local num_balls
    if [[ "$main_ball_type" == "bowling" ]]; then
        num_balls=$((2 + RANDOM % 2))  # 2-3 bowling balls
    elif [[ "$main_ball_type" == "basketball" ]]; then
        num_balls=$((2 + RANDOM % 3))  # 2-4 basketballs
    else
        num_balls=$((3 + RANDOM % 3))  # 3-5 smaller balls
    fi
    
    # Surface type affects scene setup
    local surface_type=${SURFACE_TYPES[$((RANDOM % ${#SURFACE_TYPES[@]}))]}
    
    # Coordinate system for physics (convert to pixel coordinates for naming)
    local physics_x_int=$((RANDOM % 400))
    local physics_y_int=$((RANDOM % 400))
    local physics_x=$(echo "scale=2; $physics_x_int / 100 - 2" | bc)  # -2 to 2 meters
    local physics_y=$(echo "scale=2; $physics_y_int / 100 - 2" | bc)  # -2 to 2 meters
    
    # Convert physics coordinates to pixel coordinates (simplified mapping)
    local coordx_calc=$(echo "scale=2; $physics_x * 100" | bc)
    local coordy_calc=$(echo "scale=2; $physics_y * 100" | bc)
    local coordx=$(echo "scale=0; 256 + $coordx_calc / 1" | bc)
    local coordy=$(echo "scale=0; 256 + $coordy_calc / 1" | bc)
    
    # Pixel angle for visual reference (related to force angle but not identical)
    local pixel_offset=$(echo "scale=1; $((RANDOM % 20)) - 10" | bc)
    local pixangle=$(echo "scale=1; $force_angle + $pixel_offset" | bc)
    
    echo "$main_ball_type $base_force $force_angle $coordx $coordy $pixangle $height_offset $num_balls $surface_type"
}

# Generate 5 test scenes
for i in {1..5}; do
    echo "==========================================="
    echo "Generating scene $i/5..."
    
    # Generate physics-based parameters
    params=($(generate_physics_params $i))
    BALL_TYPE=${params[0]}
    FORCE_MAGNITUDE=${params[1]}
    FORCE_ANGLE=${params[2]}
    COORDX=${params[3]}
    COORDY=${params[4]}
    PIXANGLE=${params[5]}
    HEIGHT_OFFSET=${params[6]}
    NUM_BALLS=${params[7]}
    SURFACE_TYPE=${params[8]}
    
    echo "Ball type: $BALL_TYPE"
    echo "Force: ${FORCE_MAGNITUDE}N at ${FORCE_ANGLE}°"
    echo "Starting height: ${HEIGHT_OFFSET}m"
    echo "Number of balls: $NUM_BALLS"
    echo "Surface: $SURFACE_TYPE"
    
    # Create enhanced scene name with physics meaning
    SCENE_NAME="angle_${FORCE_ANGLE}_force_${FORCE_MAGNITUDE}_coordx_${COORDX}_coordy_${COORDY}_pixangle_${PIXANGLE}"
    
    # Run Blender with enhanced physics parameters
    echo "Running Blender for scene: $SCENE_NAME"
    $BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
        --output_dir $OUTPUT_BASE_DIR \
        --scene_name $SCENE_NAME \
        --num_balls $NUM_BALLS \
        --ball_type $BALL_TYPE \
        --frames 30 \
        --resolution 512 \
        --angle $FORCE_ANGLE \
        --force $FORCE_MAGNITUDE \
        --coordx $COORDX \
        --coordy $COORDY \
        --pixangle $PIXANGLE \
        --height_offset $HEIGHT_OFFSET \
        --seed $i > /tmp/blender_output_$i.log 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo "✓ Scene $i rendered successfully!"
        
        # Check output files
        SCENE_DIR="$OUTPUT_BASE_DIR/$SCENE_NAME"
        if [[ -d "$SCENE_DIR" ]]; then
            RGB_COUNT=$(ls -1 "$SCENE_DIR/pngs"/*.png 2>/dev/null | wc -l)
            DEPTH_COUNT=$(ls -1 "$SCENE_DIR/depth"/*.png 2>/dev/null | wc -l)
            SKETCH_COUNT=$(ls -1 "$SCENE_DIR/sketch"/*.png 2>/dev/null | wc -l)
            
            echo "  RGB frames: $RGB_COUNT"
            echo "  Depth maps: $DEPTH_COUNT"  
            echo "  Sketch files: $SKETCH_COUNT"
            
            # Save physics metadata
            cat > "$SCENE_DIR/physics_metadata.json" << EOF
{
    "ball_type": "$BALL_TYPE",
    "ball_mass_kg": ${BALL_MASSES[$BALL_TYPE]},
    "ball_diameter_m": ${BALL_SIZES[$BALL_TYPE]},
    "force_magnitude_n": $FORCE_MAGNITUDE,
    "force_angle_degrees": $FORCE_ANGLE,
    "starting_height_m": $HEIGHT_OFFSET,
    "surface_type": "$SURFACE_TYPE",
    "scene_description": "Ball rolling simulation with realistic physics: ${BALL_TYPE} ball with mass ${BALL_MASSES[$BALL_TYPE]}kg receives ${FORCE_MAGNITUDE}N force at ${FORCE_ANGLE}° angle from height ${HEIGHT_OFFSET}m on ${SURFACE_TYPE} surface"
}
EOF
        else
            echo "  ✗ Output directory not created"
        fi
    else
        echo "✗ Scene $i failed to render! Check /tmp/blender_output_$i.log"
    fi
    
    echo ""
done

echo "==========================================="
echo "Fixed main script test completed!"
echo "Check results: ls -la $OUTPUT_BASE_DIR/" 