# frozen-string-literal: true

module Forme
  # The major version of Forme, updated only for major changes that are
  # likely to require modification to apps using Forme.
  MAJOR = 1

  # The minor version of Forme, updated for new feature releases of Forme.
  MINOR = 10

  # The patch version of Forme, updated only for bug fixes from the last
  # feature release.
  TINY = 0

  # Version constant, use <tt>Forme.version</tt> instead.
  VERSION = "#{MAJOR}.#{MINOR}.#{TINY}".freeze

  # The full version of Forme as a number (1.8.0 => 10800)
  VERSION_NUMBER = MAJOR*10000 + MINOR*100 + TINY

  # Returns the version as a frozen string (e.g. '0.1.0')
  def self.version
    VERSION
  end
end
