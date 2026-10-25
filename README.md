# immurok Homebrew tap

```bash
brew install --cask immurok/tap/immurok
```

Installs the same signed and notarized `.pkg` that
[immurok/app-macos](https://github.com/immurok/app-macos/releases) publishes:
`/Applications/immurok.app`, the `imk` CLI and the `pam_immurok` PAM module.
The installer asks for your password because the PAM module lives in
`/usr/local/lib/pam` and `/etc/pam.d` is edited.

```bash
brew upgrade --cask immurok      # re-runs the newer pkg over the existing install
brew uninstall --cask immurok    # runs the bundled uninstall pkg, restores /etc/pam.d
brew uninstall --zap --cask immurok   # also removes ~/.immurok and preferences
```

Requires macOS 13 Ventura or later.

## Updating the cask

`immurok/app-macos`' release workflow bumps `Casks/immurok.rb` automatically
after each `v*` tag. To do it by hand:

```bash
scripts/bump.sh 1.7.0            # downloads the pkg and fills in version + sha256
brew audit --cask --online --strict immurok/tap/immurok
```
