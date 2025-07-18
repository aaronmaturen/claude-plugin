#!/bin/bash

# Excalidraw Diagram Generator for Obsidian
# Creates FSM diagrams in Excalidraw format for atm-proof command

set -euo pipefail

# Configuration
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Documents/Obsidian/Development}"
DIAGRAMS_BASE_DIR="claude-sessions/diagrams"

# Function to generate unique ID
generate_id() {
    echo "$(date +%s)-$(uuidgen | tr '[:upper:]' '[:lower:]' | cut -c1-8)"
}

# Function to create FSM diagram
create_fsm_diagram() {
    local module_name="$1"
    local project_name="$2"
    local states="$3"
    local transitions="$4"
    
    # Create directory
    local diagram_dir="${OBSIDIAN_VAULT}/${DIAGRAMS_BASE_DIR}/${project_name}"
    mkdir -p "$diagram_dir"
    
    # Generate filename
    local filename="${module_name}-fsm-$(date +%Y%m%d-%H%M%S).excalidraw"
    local filepath="${diagram_dir}/${filename}"
    
    # Start building JSON
    cat > "$filepath" << 'EOF'
{
  "type": "excalidraw",
  "version": 2,
  "source": "claude-atm-proof",
  "elements": [
EOF
    
    # Add states
    local x=100
    local y=100
    local first=true
    
    IFS=',' read -ra STATE_ARRAY <<< "$states"
    for state in "${STATE_ARRAY[@]}"; do
        state=$(echo "$state" | xargs)  # trim whitespace
        local state_id="state-$(echo "$state" | tr '[:upper:]' '[:lower:]')"  # lowercase
        
        # Determine color based on state type
        local bg_color="#ffffff"
        local stroke_color="#000000"
        case "$state" in
            *ERROR*|*FAIL*) bg_color="#ffcccc"; stroke_color="#cc0000" ;;
            *SUCCESS*|*COMPLETE*) bg_color="#ccffcc"; stroke_color="#00cc00" ;;
            *WAIT*|*PENDING*) bg_color="#ffffcc"; stroke_color="#cccc00" ;;
        esac
        
        if [[ "$first" != "true" ]]; then
            echo "," >> "$filepath"
        fi
        first=false
        
        cat >> "$filepath" << EOF
    {
      "type": "ellipse",
      "version": 1,
      "versionNonce": $(date +%s%N),
      "isDeleted": false,
      "id": "$state_id",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "angle": 0,
      "x": $x,
      "y": $y,
      "strokeColor": "$stroke_color",
      "backgroundColor": "$bg_color",
      "width": 150,
      "height": 80,
      "seed": $(date +%s),
      "groupIds": [],
      "strokeSharpness": "sharp",
      "boundElementIds": []
    }
EOF
        
        # Add text label for state
        echo "," >> "$filepath"
        cat >> "$filepath" << EOF
    {
      "type": "text",
      "version": 1,
      "versionNonce": $(date +%s%N),
      "isDeleted": false,
      "id": "text-$state_id",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "solid",
      "roughness": 1,
      "opacity": 100,
      "angle": 0,
      "x": $((x + 75)),
      "y": $((y + 35)),
      "strokeColor": "#000000",
      "backgroundColor": "transparent",
      "width": 100,
      "height": 25,
      "seed": $(date +%s),
      "groupIds": [],
      "strokeSharpness": "sharp",
      "boundElementIds": [],
      "fontSize": 20,
      "fontFamily": 1,
      "text": "$state",
      "textAlign": "center",
      "verticalAlign": "middle"
    }
EOF
        
        # Update position for next state
        x=$((x + 250))
        if [[ $x -gt 800 ]]; then
            x=100
            y=$((y + 150))
        fi
    done
    
    # Add transitions (simplified for now)
    if [[ -n "$transitions" ]]; then
        echo "," >> "$filepath"
        echo '    {' >> "$filepath"
        echo '      "type": "text",' >> "$filepath"
        echo '      "id": "transitions-note",' >> "$filepath"
        echo '      "x": 100,' >> "$filepath"
        echo '      "y": 50,' >> "$filepath"
        echo '      "width": 300,' >> "$filepath"
        echo '      "height": 25,' >> "$filepath"
        echo '      "text": "Transitions: '"$transitions"'",' >> "$filepath"
        echo '      "fontSize": 16' >> "$filepath"
        echo '    }' >> "$filepath"
    fi
    
    # Close JSON
    cat >> "$filepath" << 'EOF'
  ],
  "appState": {
    "gridSize": 20,
    "viewBackgroundColor": "#ffffff"
  }
}
EOF
    
    echo "$filename"
}

# Function to create edge case diagram
create_edge_case_diagram() {
    local case_name="$1"
    local project_name="$2"
    local description="$3"
    
    local diagram_dir="${OBSIDIAN_VAULT}/${DIAGRAMS_BASE_DIR}/${project_name}"
    mkdir -p "$diagram_dir"
    
    local filename="${case_name}-edge-case-$(date +%Y%m%d-%H%M%S).excalidraw"
    local filepath="${diagram_dir}/${filename}"
    
    cat > "$filepath" << EOF
{
  "type": "excalidraw",
  "version": 2,
  "source": "claude-atm-proof",
  "elements": [
    {
      "type": "rectangle",
      "id": "edge-case-box",
      "x": 100,
      "y": 100,
      "width": 400,
      "height": 200,
      "strokeColor": "#cc0000",
      "backgroundColor": "#ffeeee",
      "fillStyle": "solid",
      "strokeWidth": 2,
      "strokeStyle": "dashed"
    },
    {
      "type": "text",
      "id": "edge-case-title",
      "x": 150,
      "y": 120,
      "text": "Edge Case: $case_name",
      "fontSize": 24,
      "fontFamily": 1
    },
    {
      "type": "text",
      "id": "edge-case-desc",
      "x": 150,
      "y": 180,
      "text": "$description",
      "fontSize": 16,
      "fontFamily": 1,
      "width": 300,
      "height": 100
    }
  ]
}
EOF
    
    echo "$filename"
}

# Main logic
case "${1:-help}" in
    "fsm")
        create_fsm_diagram "${2:-module}" "${3:-project}" "${4:-INIT,RUNNING,COMPLETE}" "${5:-}"
        ;;
    
    "edge-case")
        create_edge_case_diagram "${2:-edge-case}" "${3:-project}" "${4:-Description}"
        ;;
    
    "help"|*)
        echo "Usage:"
        echo "  $0 fsm <module-name> <project-name> <states> [transitions]"
        echo "  $0 edge-case <case-name> <project-name> <description>"
        echo ""
        echo "Examples:"
        echo "  $0 fsm parser my-app 'INIT,PARSING,ERROR,COMPLETE' 'parse,error,reset'"
        echo "  $0 edge-case buffer-overflow my-app 'Input size > MAX_INT'"
        ;;
esac