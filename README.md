# bundler.sh

Bundle multiple shell scripts into a single executable. 

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
```

## Examples

### Create a bundle from a set of bash scripts
```bash
# Bundle
$ ./bundler.sh -s speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh

# Execute bundle
$ ./babel.sh
Usage: ./babel.sh [command] [args...]

Available commands:
  speak
  moo
  quack

# Execute specific command in bundle
$ ./babel.sh speak 'Hello, world!'
Hello, world!
```

### Create a password protected bundle 
```bash
# Bundle
$ ./bundler.sh -p -s speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh
Password: xxx

# Execute password protected bundle (interactive password prompt)
$ ./babel.sh quack 'Hello, world!'
Password: xxx
Quack! Quack!

# Execute password protected bundle (supply password via environment variable)
$ TOKEN=xxx ./babel.sh moo 'Hello, world!'
Moo! Moo!
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).
