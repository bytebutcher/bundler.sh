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
```bash
Usage: ./bundler.sh [OPTIONS]

Description:
  Bundles multiple shell scripts into a single executable shell script.
  This allows for easy distribution and execution of multiple scripts as a single file.

Options:
  -f COMMAND:SCRIPT_PATH,...
    Specify a comma-separated list of command:script_path pairs to include in the bundle.

  -o OUTPUT_SCRIPT
    Specify the filename for the generated executable bundle.

  -p
    Prompt for a password that will be used to encrypt the bundled scripts.

Examples:
  # Bundle 'speak.sh', 'quack.sh', and 'moo.sh' into 'babel.sh'.
  ./bundler.sh -f speak:speak.sh,quack:quack.sh,moo:moo.sh -o babel.sh

  # Execute the 'speak' command within 'babel.sh'.
  ./babel.sh speak 'Hello, world!'
```

## License

This project is licensed under the [Apache License 2.0](LICENSE).
