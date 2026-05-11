# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build the library
lake build

# Run tests
lake test

# Build a specific target
lake build System.Xdg
lake build test

# Run the demo executable
lake exe xdg
```

## Architecture

This is a Lean 4 library implementing the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html) and [XDG User Directories](https://www.freedesktop.org/wiki/Software/xdg-user-dirs/).

### Library modules

- **`System/Xdg.lean`** (`namespace System.Xdg`) — Base Directory spec: `getDataHome`, `getConfigHome`, `getCacheHome`, `getStateHome`, `getRuntimeDir`, `getDataDirs`, `getConfigDirs`, and read/write helpers (`readDataFile`, `writeConfigFile`, etc.). All functions are `IO` and fall back to XDG-spec defaults when env vars are unset.

- **`System/Xdg/UserDir.lean`** (`namespace System.Xdg.UserDir`) — User directory spec (e.g. DESKTOP, DOWNLOAD). Reads `$XDG_CONFIG_HOME/user-dirs.dirs` (user config) and `/etc/xdg/user-dirs.defaults` (system defaults). User config takes precedence. Internal parsing helpers live in `System.Xdg.UserDir.Internal` and are exported for testing.

### Test structure

Tests live under `Test/` and are a `[[lean_lib]]` named `Test` in `lakefile.toml`:

- `Test/Harness.lean` — minimal test harness (`ok`, `fail`, `check`, `checkTrue`, `checkFalse`)
- `Test/Xdg.lean` — pure function tests for `System.Xdg`; exports `runXdgTests`
- `Test/UserDir.lean` — pure and IO tests for `System.Xdg.UserDir`; exports `runUserDirTests`
- `Test/Main.lean` — entry point that calls `runXdgTests` and `runUserDirTests`

The `Internal` namespace in `UserDir.lean` is intentionally public so unit tests can reach parsing helpers (`parsePair`, `expandVarsIO`, `pairToXdgPair`, `readPairs`, `getUserDirWithCustomGetEnv`, etc.) directly.

### `getUserDir` lookup order

`getUserDir key` merges `readUserDirs` (from `user-dirs.dirs`) and `readDefaults` (from `/etc/xdg/user-dirs.defaults`), with user entries prepended so `List.lookup` finds them first. Returns `Option FilePath` — `none` if the key is absent from both sources.
