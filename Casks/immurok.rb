cask "immurok" do
  version "1.6.7"
  sha256 "7e3817ac54212a6d1c8c746eff969d9c3607f6edb0e5a0b32e55ab458ae6b7d7"

  url "https://github.com/immurok/app-macos/releases/download/v#{version}/immurok-#{version}.pkg"
  name "immurok"
  desc "Bluetooth fingerprint authentication for screen unlock, sudo and PAM"
  homepage "https://immurok.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: :ventura

  # The signed + notarized pkg installs /Applications/immurok.app,
  # /usr/local/bin/imk and /usr/local/lib/pam/pam_immurok.so, and its
  # postinstall wires pam_immurok into /etc/pam.d/sudo_local + authorization.
  pkg "immurok-#{version}.pkg"

  # `pkgutil:` alone would leave the /etc/pam.d edits behind, so run the
  # uninstall pkg that ships inside the app first; it reverts them and
  # removes every installed file. The receipts are forgotten afterwards.
  # must_succeed: false keeps `brew uninstall` working when the app was
  # already removed by hand (or via the app's own uninstall action).
  uninstall quit:    "com.immurok.app",
            script:  {
              executable:   "/usr/sbin/installer",
              args:         [
                "-pkg", "/Applications/immurok.app/Contents/Resources/immurok_uninstall.pkg",
                "-target", "/"
              ],
              sudo:         true,
              must_succeed: false,
            },
            pkgutil: [
              "com.immurok.pkg",
              "com.immurok.repair",
              "com.immurok.uninstall",
            ]

  zap trash: [
    "~/.immurok",
    "~/Library/Preferences/com.immurok.app.plist",
  ]
end
