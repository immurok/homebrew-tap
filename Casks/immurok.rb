cask "immurok" do
  version "1.6.12"
  sha256 "d1d81737058d6a56c0a278f72a9dba44a60769fb52df1586dc408cecd2de8c1d"

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

  # The pkg's postinstall adds a line to /etc/pam.d/sudo_local and
  # /etc/pam.d/authorization that points at pam_immurok.so. Those edits are
  # not in the pkg receipt, so removing files by receipt (`pkgutil:`) while
  # the lines are still there leaves PAM pointing at a missing module, and
  # PAM then fails to initialise the whole service: sudo and the system
  # authorization dialog both stop working.
  #
  # So the uninstall pkg must run first (it reverts the lines, removes the
  # app and CLI, and forgets the receipts; it leaves pam_immurok.so on disk
  # on purpose, since an unreferenced module is harmless and a missing one
  # is not), and it MUST succeed:
  # with must_succeed: false a declined permission prompt or a missing
  # uninstall pkg let brew carry on and delete the module anyway.
  #
  # The uninstall pkg is looked up outside the app bundle first, so it is
  # still there when the app was dragged to the Trash. If neither copy
  # exists, the script only lets brew continue when nothing in /etc/pam.d
  # references the module any more.
  uninstall quit:    "com.immurok.app",
            script:  {
              executable:   "/bin/sh",
              args:         [
                "-c",
                <<~SH,
                  for p in "/Library/Application Support/immurok/immurok_uninstall.pkg" \
                           "/Applications/immurok.app/Contents/Resources/immurok_uninstall.pkg"; do
                    if [ -f "$p" ]; then
                      exec /usr/sbin/installer -pkg "$p" -target /
                    fi
                  done
                  if grep -qsE '^[^#]*pam_immurok' /etc/pam.d/*; then
                    echo "immurok: uninstall pkg not found and /etc/pam.d still references pam_immurok.so." >&2
                    echo "immurok: reinstall immurok, then uninstall again. Nothing was removed." >&2
                    exit 1
                  fi
                  exit 0
                SH
              ],
              sudo:         true,
              must_succeed: true,
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
