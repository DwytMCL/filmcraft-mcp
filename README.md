# filmcraft-mcp

Lets Claude (or any MCP client) drive the [FilmCraft](https://github.com/storytold/filmcraft) video editor on macOS: sync audio by waveform or timecode, make cuts, lift/extract ranges, move clips, mix audio, export.

FilmCraft already ships an MCP server in `filmcraft-cli mcp --bridge`, but the released app doesn't include that CLI. This repo is the glue: build instructions plus `filmcraft-mcp.sh`, a launcher that

1. creates a control token (in `.token`, readable only by you),
2. starts FilmCraft with its localhost control port (9876, or `FILMCRAFT_CONTROL_PORT`) if it isn't running,
3. runs the MCP bridge on stdio.

## Setup

Requires Rust (`cargo`) and FilmCraft in `/Applications`.

```sh
git clone https://github.com/DwytMCL/filmcraft-mcp ~/filmcraft-mcp
cd ~/filmcraft-mcp
# build the CLI at the same version as your installed app
git clone https://github.com/storytold/filmcraft src
git -C src checkout "$(defaults read /Applications/FilmCraft.app/Contents/Info FilmCraftBuildCommit)"
cargo build --release -p filmcraft-cli --manifest-path src/Cargo.toml
```

Register it:

```sh
claude mcp add -s user filmcraft ~/filmcraft-mcp/filmcraft-mcp.sh
```

For Claude Desktop, add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{ "mcpServers": { "filmcraft": { "command": "/Users/YOU/filmcraft-mcp/filmcraft-mcp.sh" } } }
```

## Use

Quit FilmCraft first: an app opened from the Dock has no control port, so let the MCP start it.

Useful commands (via the `command_run` tool, `{"id": ..., "params": ...}`):

| Task | Command |
|---|---|
| Sync clips by audio | `clip.synchronize {"method": "audio"}` (also `timecode`, `in`, `out`, `marker`) |
| Marry camera + recorder audio | `clip.mergeClips {"method": "audio"}` |
| Cut at a time | `sequence.addEdit` / `sequence.addEditAllTracks {"seconds": 5}` |
| Remove a range | `sequence.lift` (leave gap) / `sequence.extract` (close gap) |
| Match loudness | `essentialSound.autoMatch` |

`command_list` lists every command. See upstream [docs/control-protocol.md](https://github.com/storytold/filmcraft/blob/main/docs/control-protocol.md).

When FilmCraft updates, rebuild the CLI at the new commit.

## License

MIT. FilmCraft itself is MIT/Apache-2.0 and is not included here.
