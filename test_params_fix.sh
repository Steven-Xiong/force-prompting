#!/bin/bash

# 测试修复后的参数生成函数
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
SURFACE_TYPES=("grass" "concrete" "dirt" "wood" "carpet")

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

# 测试修复后的参数生成
echo "Testing FIXED parameter generation:"
for i in {1..3}; do
    echo "--- Test $i ---"
    params=($(generate_physics_params $i))
    echo "Ball type: ${params[0]}"
    echo "Force magnitude: ${params[1]}"
    echo "Force angle: ${params[2]}"
    echo "CoordX: ${params[3]}"
    echo "CoordY: ${params[4]}"
    echo "Pixangle: ${params[5]}"
    echo "Height offset: ${params[6]}"
    echo "Num balls: ${params[7]}"
    echo "Surface type: ${params[8]}"
    echo ""
done 