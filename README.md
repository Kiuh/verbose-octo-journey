# Verbose-Octo-Journey

A solid monorepo with little try to make something that <br>
looks like bundle of interesting projects with modularized structure.


## Structure

An root `build.zig` it's utility to inspect what repo contains <br>
and easy access to repo content.

Repository structure:
```
├── modules/     # libraries and utilities without executable options 
├── programs/    # executables and helpers
├── projects/    # logically separated projects
├── ...
└── build.zig
```

Run
```sh
zig build --help
```
to see all available options.

## And remember

 * Communicate intent precisely.
 * Edge cases matter.
 * Favor reading code over writing code.
 * Only one obvious way to do things.
 * Runtime crashes are better than bugs.
 * Compile errors are better than runtime crashes.
 * Incremental improvements.
 * Avoid local maximums.
 * Reduce the amount one must remember.
 * Focus on code rather than style.
 * Resource allocation may fail; resource deallocation must succeed.
 * Memory is a resource.
 * Together we serve the users.