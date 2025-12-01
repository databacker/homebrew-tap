class MysqlBackup < Formula
  desc "Automated backups of mysql databases"
  homepage "https://github.com/databacker/mysql-backup"
  license "Apache-2.0"

  # HEAD: build from source
  head do
    url "https://github.com/databacker/mysql-backup.git", branch: "master"
    depends_on "go" => :build
  end

  # Default: use pre-built binary
  on_macos do
    on_arm do
      url "https://github.com/databacker/mysql-backup/releases/download/v1.3.0/mysql-backup-darwin-arm64"
      sha256 "5240a9a3d82a616e6608dc29e71ac2451ae82cd8ba68d9e76136381f185a85c6"
    end
    on_intel do
      url "https://github.com/databacker/mysql-backup/releases/download/v1.3.0/mysql-backup-darwin-amd64"
      sha256 "23ba2fe32ad50bfe2571c1ea88962df9ef1051ea06411b4969f7ff0398fb176e"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/databacker/mysql-backup/releases/download/v1.3.0/mysql-backup-linux-arm64"
      sha256 "3b72ece958b6f52d5b90997d63f68a12885f6a78d185acbf93588709d4002ceb"
    end
    on_intel do
      url "https://github.com/databacker/mysql-backup/releases/download/v1.3.0/mysql-backup-linux-amd64"
      sha256 "c281bd060d7ff40ca4f2e137bcd4e3ad289a4b3adf8f9fc0e5bf04b8746e5461"
    end
  end

  def install
    if build.head?
      # Build from source for HEAD
      system "go", "build", *std_go_args(ldflags: "-s -w"), "./cmd/mysql-backup"
    else
      # Install pre-built binary
      arch_binary = Dir["mysql-backup-*"].first
      raise "Binary not found!" unless arch_binary

      mv arch_binary, "mysql-backup"
      bin.install "mysql-backup"
    end
  end

  test do
    system "#{bin}/mysql-backup", "--version"
  end
end
