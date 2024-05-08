#!/bin/bash
# ##################################################
# NAME:
#   bundler.sh
# DESCRIPTION:
#   Bundle multiple shell scripts into a single 
#   executable. 
# AUTHOR:
#   bytebutcher
# ##################################################

APP_NAME="$(basename "${BASH_SOURCE}")"

# Check if the 'zip' command is available
if ! command -v zip &> /dev/null; then
    echo "Error: 'zip' command not found. Please make sure it is installed and in your PATH." >&2
    exit 1
fi

usage() {
    if [[ "$1" == "-v" ]]; then
        echo "Usage: $APP_NAME [OPTION]..."
        echo "Try '$APP_NAME -h' for more information."
        exit 1
    else
        cat <<EOF >&2
Usage: $APP_NAME [OPTIONS]

Description:
  Bundles multiple shell scripts into a single executable.

Options:
  -s COMMAND:SCRIPT_PATH,...
    Specify a comma-separated list of command:script_path pairs to include in the bundle.

  -o OUTPUT_SCRIPT
    Specify the filename for the generated executable bundle.

  -f
    Force overwriting the output file if it already exists.

  -p
    Prompt for a password that will be used to encrypt the bundled scripts.

  -h
    Display this help message and exit.

Examples:
  # Create a bundle from a set of bash scripts
  \$ $APP_NAME -s speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh
  
  # Execute bundle
  \$ ./babel.sh speak 'Hello, world!'
  Hello, world!

  # Create a password protected bundle
  \$ $APP_NAME -s speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh -p
  Password: xxx

  # Execute password protected bundle (interactive password prompt)
  \$ ./babel.sh quack 'Hello, world!'
  Password: xxx
  Quack! Quack!

  # Execute password protected bundle (supply password via environment variable)
  \$ TOKEN=xxx ./babel.sh moo 'Hello, world!'
  Moo! Moo!

EOF
        exit 1
    fi
}

force_output=false
use_password=false

# Show short usage, if no parameters where supplied
if [[ $# -eq 0 ]]; then
    usage -v
fi

# Parse arguments
while getopts "s:o:phf" opt; do
    case "$opt" in
        s) IFS=',' read -r -a pairs <<< "$OPTARG"
           declare -A scripts
           for pair in "${pairs[@]}"; do
               IFS=':' read -r key value <<< "$pair"
               scripts[$key]=$value
           done
           ;;
        o) output="$OPTARG"
           ;;
        f) force_output=true 
           ;;
        p) use_password=true
           ;;
        h) usage
           ;;
        *) usage -v
           ;;
    esac
done

# Check if any script file was specified
if [ ${#scripts[@]} -eq 0 ]; then
    echo "Error: No script files specified." >&2
    exit 1
fi

# Check if each script file exists and fulfills constraints
declare -A filename_check
for script_file in "${scripts[@]}"; do
    if [[ ! -f "$script_file" ]]; then
        echo "Error: Script file '$script_file' does not exist." >&2
        exit 1
    fi
    filename=$(basename "$script_file")
    if [[ "$filename" == "entrypoint.sh" ]]; then
        echo "Error: The filename 'entrypoint.sh' is reserved and cannot be used." >&2
        exit 1
    fi
    if [[ -n "${filename_check[$filename]}" ]]; then
        echo "Error: Duplicate filename '$filename' detected. Filenames must be unique." >&2
        exit 1
    fi
    filename_check[$filename]=1
done

# Check if output file is set
if [[ -z "$output" ]]; then
    echo "Error: Output file not specified." >&2
    usage -v
fi

# Check if output file already exists
if [[ -e "$output" ]] && [[ $force_output == false ]] ; then
    echo "Error: Output file '$output' already exists. Use -f to force overwriting." >&2
    exit 1
fi

# Check if we need to ask for a password
if [[ $use_password == true ]] ; then
    read -s -p "Password: " password
    echo >&2
fi

# Create a temporary directory
temp_dir=$(mktemp -d)
if [ $? -ne 0 ]; then
    echo "Error: Failed to create temporary directory." >&2
    exit 1
fi

# Copy script to the temporary directory and update array
for key in "${!scripts[@]}"; do
    script_path="${scripts[$key]}"
    filename=$(basename "$script_path")
    cp "$script_path" "$temp_dir/$filename"
    scripts[$key]="$filename"
done

# Create the entrypoint script in the temporary directory
entrypoint_sh="$temp_dir/entrypoint.sh"
cat > "$entrypoint_sh" << EOF
#!/bin/bash
# Specification of the available scripts
declare -A scripts
EOF

# Start the serialization of the associative array
for cmd in "${!scripts[@]}"; do
    script_path="${scripts[$cmd]}"
    printf "scripts[%q]=%q\n" "$cmd" "$script_path" >> "$entrypoint_sh"
done

cat >> "$entrypoint_sh" << 'EOF'
BUNDLED_SCRIPT_NAME=$(basename "$BUNDLED_SCRIPT_PATH")
usage() {
    echo "Usage: $BUNDLED_SCRIPT_NAME [command] [args...]" >&2
    echo "" >&2
    echo "Available commands:" >&2
EOF

# Append available commands to the usage information
for cmd in "${!scripts[@]}"; do
    echo "    echo \"  $cmd\" >&2" >> "$entrypoint_sh"
done

cat >> "$entrypoint_sh" << 'EOF'
    echo "" >&2
    exit 1
}

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    usage
fi

# Check if the command is valid and exists in the scripts array
if [[ -n "${scripts[$1]}" ]]; then
    cmd=$1
    script_path=${scripts[$cmd]}
    shift
    execute_bundled_script "$script_path" "$@"
    exit 0
else
    echo "Invalid command: $1" >&2
    usage
fi
EOF

# Create the runner script in the temporary directory
output_sh="$temp_dir/output.sh"
cat > "$output_sh" << EOF
#!/bin/bash

# Allow bundled scripts to reference the main script's location
export BUNDLED_SCRIPT_PATH=\$(readlink -f "\${BASH_SOURCE[0]}")

# Specifies whether the bundled scripts are password proteced.
export PASSWORD_PROTECTED=$use_password

EOF

cat >> "$output_sh" << 'EOF'
# Checks if the 'unzip' command is available
if ! command -v unzip &> /dev/null; then
    echo "Error: 'unzip' command not found. Please make sure it is installed and in your PATH." >&2
    exit 1
fi

# Prompts for a password if bundle is password protected
if [[ $PASSWORD_PROTECTED == true ]] && [ -z $TOKEN ] ; then
    read -s -p "Password: " TOKEN
    echo >&2
fi

# Execute bundled script. This function can also be called from a bundled script. 
execute_bundled_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    shift
    if [[ $PASSWORD_PROTECTED == false ]]; then
        unzip -p "$BUNDLED_SCRIPT_PATH" "$script_path" 2>/dev/null | exec -a "$script_name" bash -s -- "$@"
    else
        unzip -P $TOKEN -p "$BUNDLED_SCRIPT_PATH" "$script_path" 2>/dev/null | exec -a "$script_name" bash -s -- "$@"
    fi
}
export -f execute_bundled_script

EOF

cat >> "$output_sh" << EOF
# Call entrypoint showing program usage and redirecting program flow to bundled scripts
execute_bundled_script "entrypoint.sh" "\$@"
exit \$?
EOF

# Create a zip file of the scripts in the temporary directory
cd $temp_dir
scripts[entrypoint]="entrypoint.sh"
if [[ -n "$password" ]]; then
    zip -P "$password" -q "$output.zip" "${scripts[@]}"
else
    zip -q "$output.zip" "${scripts[@]}"
fi
cd - &>/dev/null

# Bundle the runner script and the zip file into the final script
cat "$output_sh" "$temp_dir/$output.zip" > "$output"
chmod +x "$output"

# Cleanup: remove the temporary directory and its contents
rm -r "$temp_dir"

echo "Bundling complete. Run your scripts with ./$output <command> [arguments]"
