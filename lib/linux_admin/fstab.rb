# LinuxAdmin fstab Representation
#
# Copyright (C) 2013 Red Hat Inc.
# Licensed under the MIT License

require 'singleton'

class LinuxAdmin
  class FSTabEntry < LinuxAdmin
    attr_accessor :device
    attr_accessor :mount_point
    attr_accessor :fs_type
    attr_accessor :mount_options
    attr_accessor :dumpable
    attr_accessor :fsck_order
    attr_accessor :comment

    def initialize(args = {})
      @device        = args[:device]
      @mount_point   = args[:mount_point]
      @fs_type       = args[:fs_type]
      @mount_options = args[:mount_options]
      @dumpable      = args[:dumpable].to_i unless args[:dumpable].nil?
      @fsck_order    = args[:fsck_order].to_i unless args[:fsck_order].nil?
      @comment       = args[:comment]
    end

    def self.from_line(fstab_line)
      columns, comment = fstab_line.split('#')
      comment = "##{comment}" unless comment.blank?
      columns = columns.chomp.split

      FSTabEntry.new :device        => columns[0],
                     :mount_point   => columns[1],
                     :fs_type       => columns[2],
                     :mount_options => columns[3],
                     :dumpable      => columns[4],
                     :fsck_order    => columns[5],
                     :comment       => comment
    end

    def has_content?
      !self.columns.first.nil?
    end

    def columns
      [self.device, self.mount_point, self.fs_type,
       self.mount_options, self.dumpable, self.fsck_order, self.comment]
    end

    def column_lengths
      self.columns.collect { |c| c ? c.size : 0 }
    end

    def formatted_columns(max_lengths)
      self.columns.collect.
        with_index { |col, i| col.to_s.rjust(max_lengths[i]) }.join(" ")
    end
  end

  class FSTab < LinuxAdmin
    include Singleton

    attr_accessor :entries
    attr_accessor :maximum_column_lengths

    def initialize
      refresh
    end

    def write!
      content = ''
      comment_index = 0
      @entries.each do |entry|
        if entry.has_content?
          content << entry.formatted_columns(@maximum_column_lengths) << "\n"
        else
          content << "#{entry.comment}"
        end
      end

      File.write('/etc/fstab', content)
      self
    end

    private

    def read
      File.read('/etc/fstab').lines
    end

    def refresh
      @entries  = []
      @maximum_column_lengths = Array.new(7, 0) # # of columns
      read.each do |line|
        entry = FSTabEntry.from_line(line)
        @entries << entry

        lengths = entry.column_lengths
        lengths.each_index do |i|
          @maximum_column_lengths[i] =
            lengths[i] if lengths[i] > @maximum_column_lengths[i]
        end
      end
    end
  end
end
