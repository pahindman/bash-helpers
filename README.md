# bash-helpers

A small collection of Bash utility scripts for terminal status indicators and argument parsing. The scripts are designed to be sourced from other Bash scripts rather than executed directly.

## Included helpers

### `getopt.bash`

Wraps the system `getopt` command so a script can source the helper, pass its short and long option specs, and then iterate over a canonicalized argument list.

Typical pattern:

```bash
source getopt.bash "ho:" "help,opt:" "$0" "$@"

while true; do
  opt=$1
  shift
  case "$opt" in
    -h|--help)
      echo "Usage: $0 [-h|--help] [-o|--opt]"
      exit 0
      ;;
    -o|--opt)
      option_value=$1
      shift
      ;;
    --)
      break
      ;;
    *)
      echo "Error: getopt was configured incorrectly." >&2
      exit 3
      ;;
  esac
done
```

### `progress_bar.bash`

Provides a simple progress bar in the terminal margin. Use the public API:

- `progress_bar::start`
- `progress_bar::update -c "caption" -n <value> -t <total>`
- `progress_bar::stop`

The script installs SIGWINCH and EXIT handlers that preserve any existing traps already set by the parent script, as implemented in `trap.bash`.

### `spinner.bash`

Provides spinner helpers for terminal status messages. Supported entry points include:

- `automatic_spinner::start_at_cursor "message" [sleep_time]`
- `automatic_spinner::start_in_margin "message" [sleep_time]`
- `manual_spinner::start_at_cursor "message"`
- `manual_spinner::start_in_margin "message"`
- `spinner::stop "done message"`

The spinner redraws itself cleanly and restores terminal state when stopped.

### `terminal.bash`

Low-level terminal helpers for saving/restoring cursor position, moving the cursor, erasing lines, and setting a scroll region. This is the building block used by the spinner and progress bar helpers.

### `trap.bash`

Manages chained signal traps so multiple scripts or modules can append and remove handlers without clobbering each other.

## Installing the helpers

The repository includes a `Makefile` that links each top-level `*.bash` helper into `$HOME/.local/bin` by default:

```bash
make install
```

The install location is controlled by the `PREFIX` variable:

```bash
PREFIX=/usr/local make install
```

To remove the symlinks created by the repo:

```bash
make uninstall
```

## Testing

The repository’s test suite is in `test/` and uses Bats.

Before running tests, initialize the pinned Git submodules from `.gitmodules`:

```bash
git submodule update --init --recursive
```

Then install Bats and run the suite:

```bash
bats test --print-output-on-failure
```

The GitHub Actions workflow in `.github/workflows/ci.yml` does the same setup with `actions/checkout` using `submodules: recursive` and `bats-core/bats-action` before invoking:

```bash
bats test --print-output-on-failure
```

## Repository structure

- `*.bash` — sourceable Bash helper libraries
- `test/*.bats` — Bats coverage for the helper APIs
- `Makefile` — install/uninstall helpers into a `bin` directory
- `.github/workflows/ci.yml` — CI test workflow
