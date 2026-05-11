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

# Run the demo executable
lake exe xdg
```

## Architecture

This is a Lean 4 library implementing the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

### Library modules

- **`System/Xdg.lean`** (`namespace System.Xdg`) — Base Directory spec: `getDataHome`, `getConfigHome`, `getCacheHome`, `getStateHome`, `getRuntimeDir`, `getDataDirs`, `getConfigDirs`, and read/write helpers (`readDataFile`, `writeConfigFile`, etc.). All functions are `IO` and fall back to XDG-spec defaults when env vars are unset.

### Test structure

Tests live under `Test`.
