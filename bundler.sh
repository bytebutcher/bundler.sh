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
Usage: $0 [OPTIONS]

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
  \$ $0 -s speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh
  
  # Execute bundle
  \$ ./babel.sh speak 'Hello, world!'
  Hello, world!

  # Create a password protected bundle
  \$ $0 -s speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh -p
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

# Check if each script file exists
for script_file in "${scripts[@]}"; do
    if [[ ! -f "$script_file" ]]; then
        echo "Error: Script file '$script_file' does not exist." >&2
        exit 1
    fi
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

# Create a zip file of the scripts in the temporary directory
if [[ -n "$password" ]]; then
    zip -P "$password" -q "$temp_dir/$output.zip" "${scripts[@]}"
else
    zip -q "$temp_dir/$output.zip" "${scripts[@]}"
fi

# Create the runner script in the temporary directory
output_sh="$temp_dir/output.sh"
cat > "$output_sh" << EOF
#!/bin/bash
PASSWORD_PROTECTED=$use_password

usage() {
    echo "Usage: \$0 [command] [args...]" >&2
    echo "" >&2
    echo "Available commands:" >&2
EOF

# Append available commands to the usage information
for cmd in "${!scripts[@]}"; do
    echo "    echo \"  $cmd\" >&2" >> "$output_sh"
done

cat >> "$output_sh" << 'EOF'
    echo "" >&2
    exit 1
}

# Check if the 'unzip' command is available
if ! command -v unzip &> /dev/null; then
    echo "Error: 'unzip' command not found. Please make sure it is installed and in your PATH." >&2
    exit 1
fi

# Check if any arguments were provided
if [ $# -eq 0 ]; then
    usage
fi

if [[ $PASSWORD_PROTECTED == true ]] && [ -z $TOKEN ] ; then
    read -s -p "Password: " TOKEN
    echo >&2
fi

case "$1" in
EOF

# Append case entries for each command
for cmd in "${!scripts[@]}"; do
    script_path=${scripts[$cmd]}
    cat >> "$output_sh" << EOF
  $cmd)
    shift
    script_name=$(basename "$script_path")
    if [[ \$PASSWORD_PROTECTED == false ]] ; then
      unzip -p "\$0" "$script_path" 2>/dev/null | exec -a "\$script_name" bash -s -- "\$@"
    else
      unzip -P \$TOKEN -p "\$0" "$script_path" 2>/dev/null | exec -a "\$script_name" bash -s -- "\$@"
    fi
    exit 0
    ;;
EOF
done

# Close the case statement with an error default
cat >> "$output_sh" << 'EOF'
  *)
    echo "Invalid command: $1" >&2
    usage
    ;;
esac
EOF

# Bundle the runner script and the zip file into the final script
cat "$output_sh" "$temp_dir/$output.zip" > "$output"
chmod +x "$output"

# Cleanup: remove the temporary directory and its contents
rm -r "$temp_dir"

echo "Bundling complete. Run your scripts with ./$output <command> [arguments]"
