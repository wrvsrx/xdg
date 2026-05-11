# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build the library
lake build

# Run tests
lake test

# Build a specific target
lake build Xdg
```

## Architecture

This is a Lean 4 library implementing the [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

The project has a flat structure with two Lean files:

- **`Xdg.lean`** (`namespace System.Xdg`) — Full implementation. Exposes two inductive types (`XdgDirectory` for single user dirs, `XdgDirectoryList` for system-wide search paths) and four public functions: `getXdgDirectory`, `getXdgDirectoryList`, `getHomeDirectory`, `getTemporaryDirectory`. All functions are `IO` and fall back to XDG-spec defaults when env vars are unset. `XdgDirectory.Runtime` (`XDG_RUNTIME_DIR`) is an extension beyond the Haskell `directory` library API that the rest of the public API mirrors.
- **`XdgTest/Basic.lean`** — Unit tests for `parseXdgDirs` using `#guard_msgs`.
