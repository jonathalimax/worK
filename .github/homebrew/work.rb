cask "work" do
  version "1.0.0"
  sha256 "ff32a6bff0a758a0be26b28c2c61a0184ef4c71f771bc11a08bb2b6f614a7ecb"

  url "https://github.com/jonathalimax/worK/releases/download/v#{version}/worK-#{version}.dmg"
  name "worK"
  desc "Automatic work time tracking that lives in your menu bar"
  homepage "https://github.com/jonathalimax/worK"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "worK.app"

  zap trash: [
    "~/Library/Application Support/worK",
    "~/Library/Preferences/com.jonathalimax.worK.plist",
  ]
end
