# frozen_string_literal: true

require "stitch_fix/y/tasks"

module StitchFix
  module LogWeasel
    module VersionTask
      class << self
        def new(gemspec)
          StitchFix::Y::VersionTask.new(gemspec)
        end
      end
    end
  end
end
