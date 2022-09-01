Debug `SF Pro` font rendering in Pango.

[./output](./output) contains `pango-view` renderings for both font versions (see below) and different Pango versions (all built with the exact same dependencies).

### Fonts

- `SF-Pro-Display-Regular.otf`: OpenType/Postscript version of `SF Pro`, extracted
  from the [official download](https://developer.apple.com/fonts/) (`SF-Pro.dmg` fetched at 2022-09-01, SHA256 `1ed27f29d21539d62872ecd0f2a9334c09bb6cc2130aadd29eff81a3d58ef620`)
- `SFNSDisplay.ttf`: TrueType version of `SF Pro`, the included font variants have name `System Font *`

### Recreate `pango-view` renderings in ./output

1. Install [Nix](https://nixos.org/download.html)

2. Run
   ```bash
   nix build --no-link --print-out-paths
   ```

### More features
- Start a dev environment for manually running [./main.sh](./main.sh)
  ```bash
  nix run
  ```
- [manual-build/main.sh](manual-build/main.sh) is a build and bisect helper
