# frozen_string_literal: true

require "stitch_fix/y/tasks"

module StitchFix
  module LogWeasel
    module ReleaseTask
      class << self
        def new(gemspec)
          StitchFix::Y::ReleaseTask.new(gemspec)
        end
      end
    end
  end
end
