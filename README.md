# bundler.sh

Bundler allows you to bundle multiple shell scripts into a single executable shell script. This makes distribution and execution of multiple scripts as a single file convenient and easy.

## Features

- Bundles multiple shell scripts into a single executable script.
- Optional password protection for bundled scripts.
- In-Memory execution

## Setup

```bash
git clone https://github.com/bytebutcher/bundler.sh.git && cd bundler.sh && chmod +x bundler.sh
```

## Usage
```
Usage: ./bundler.sh [OPTIONS]

Description:
  Bundles multiple shell scripts into a single executable.
  This allows for easy distribution and execution of multiple scripts as a single file.

Options:
  -f COMMAND:SCRIPT_PATH,...
    Specify a comma-separated list of command:script_path pairs to include in the bundle.

  -o OUTPUT_SCRIPT
    Specify the filename for the generated executable bundle.

  -p
    Prompt for a password that will be used to encrypt the bundled scripts.
```

## Examples

### Create a bundle from a set of bash scripts
```bash
# Bundle
%> ./bundler.sh -f speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh

# Execute bundle
%> ./babel.sh
Usage: ./babel.sh [command] [args...]

Available commands:
  speak
  moo
  quack

# Execute specific command in bundle
%> ./babel.sh speak 'Hello, world!'
Hello, world!
```

### Create a password protected bundle 
```bash
# Bundle
%> ./bundler.sh -p -f speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh
Password: xxx

# Execute password protected bundle
TOKEN=xxx ./babel.sh moo 'Hello, world!'
Moo! Moo! Moo! 
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).
