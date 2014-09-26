# Ruby SMPTE time class
#
# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2014 Michael Chaney Consulting Corporation, All Rights Reserved
#
# Released publicly under the terms of the MIT License or GNU Public
# License v2.
#
# # smpte for 1 hour, 50 minutes, and 30 seconds
# smpte = SMPTE.new('01:50:30')
# smpte.to_i
#  => 198900
#
# smpte2 = SMPTE.new('01:20:00')
# smpte - smpte2
# => #<SMPTE:0x00000100d42b40 @frames=0, @seconds=30, @minutes=30, @hours=0, @has_frames=true, @has_subframes=false, @frame_count=54900, @df="ndf", @ten_minute_periods=0>
#
# smpte4 = SMPTE.new(107892, 'df')
# smpte4.to_s
# => "01:00:00;00"
#
# smpte5 = SMPTE.new(108000, 'ndf')
# smpte5.to_s
# => "01:00:00:00"
#
# Methods "to_i", "to_f" and "to_s" are available to convert to integer
# (frame count), float (frame count with optional subframe count) and string
# respectively.
#
# You can use "+" to add an integer number of frames to a SMPTE which will
# return another SMPTE,
#
# You can use "-" to subtract one SMPTE from another returning a SMPTE.
#
# You can use "<=>" to compare two SMPTE objects.  Enumerable is mixed in
# to give you "<", ">", etc.
#
# Note that the SMPTE objects are immutable.
#
# The constructor can accept one of the following:
# string in SMPTE format (HH:MM:SS:FF.SF)
# where "FF" is a frame count and "SF" is subframes count (both optional)
# string in SMPTE format (HH:MM:SS;FF.SF)
# Note the semi-colon - this forced "drop frame format" (see below)
#
# integer - frame count
# float - frame count - decimal portion is subframes
# SMPTE - another SMPTE
#
# The second parameter to the initializer is "df" or "ndf" for "drop frame"
# and "non-drop frame" format respectively.  The default is "ndf" unless
# the frame count is preceded by a semi-colon in which case the default
# is "df".
#
# Drop Frame vs. Non-Drop Frame format
#
# Drop frame format:
# Two frame numbers - "00" and "01" - are dropped every minute
# ( 2 x 60 = 120 frame numbers ) EXCEPT for minute points that
# have a "0" number - 00, 10, 20, 30, 40 and 50 minutes -
# ( 2 x 6 = 12 frames ). This results in 120-12 or 108 frame
# numbers (not frames) being skipped.
#
# One hour of NTSC video has 107,892 instead of 108,000 frames.
# Ten minutes of NTSC video has 17,982 frames instead of 18,000.

class SMPTE
  include Comparable

  attr_reader :frame_count, :has_frames, :has_subframes, :df, :hours, :minutes, :seconds, :frames, :subframes

  def self.valid?(string)
    string.to_s.match(/(\d\d):(\d\d):(\d\d)(?:[:;](\d\d)(\.\d+)?)?/)
  end

  # This can be initialized in one of four ways:
  #
  # smpte string - with or without frame count
  # integer frame count
  # floating point frame count
  # another smpte object
  def initialize(string, df=nil)
    if string.kind_of?(String) && string.to_s =~ /(\d\d):(\d\d):(\d\d)(?:([:;])(\d\d)(\.\d+)?)?/
      @hours, @minutes, @seconds, sep, @frames, @subframes = $1.to_i, $2.to_i, $3.to_i, $4, $5, $6
      @has_frames = !@frames.nil?
      @frames = 0 unless @frames
      @frames = @frames.to_i
      @has_subframes = !@subframes.nil?
      @subframes = @subframes.to_f   # note that nil.to_f == 0.0
      @frame_count = (((@hours * 60) + @minutes) * 60 + @seconds) * 30 + @frames
      if df.to_s == 'df' || df.to_s == 'drop frame' || sep == ';'
        @df = 'df'
      else
        @df = 'ndf'
      end
      if @df == 'df'
        # Every hour, we drop 108 frame #'s.  Every minute, we drop 2 frame
        # #'s, except for the even 10 minutes (00, 10, 20, 30, 40, & 50).
        # The numbers that are dropped are frames 00 and 01, meaning that we
        # have to subtract two for each minute > 0.
        #
        # Consider, 00:02:59:29, next frame is 00:03:00:02, so 00 and 01 were
        # skipped.  This is going to make to_s fun fun fun...
        @frame_count -= (@hours * 108)
        @frame_count -= ((@minutes/10).floor * 18)
        # In reality, this is a sanity check.  03:01:00:01 isn't a valid
        # drop-frame smpte code.
        # But if it shows up, I'm not going to subtract two frames for it.
        if @minutes%10 >= 1
          if @frames >=2 || @seconds > 0
            @frame_count -= (@minutes%10)*2
          else
            @frame_count -= ((@minutes%10)-1)*2
          end
        end
      end
    elsif string.kind_of?(SMPTE)
      @frame_count = string.to_i
      @has_frames = string.has_frames
      @has_subframes = string.has_subframes
      @df = df.nil? ? string.df : ((df.to_s=='df' || df.to_s=='drop frame') ? 'df' : 'ndf')
      @hours = string.hours
      @minutes = string.minutes
      @seconds = string.seconds
      @frames = string.frames
      @subframes = string.subframes
    elsif string.kind_of?(Integer)
      @frame_count = string.to_i
      @has_frames = true
      @has_subframes = false
      @df = (df.to_s=='df' || df.to_s=='drop frame') ? 'df' : 'ndf'
      compute_times
    elsif string.kind_of?(Float)
      @frame_count = string.floor
      @subframes = string - @frame_count.to_f
      @has_frames = true
      @has_subframes = true
      @df = (df.to_s=='df' || df.to_s=='drop frame') ? 'df' : 'ndf'
      compute_times
    else
      raise "What is this? #{string}"
      false
    end
    if @has_subframes
      @frame_count = @frame_count.to_f + @subframes
    end
  end

  def eql?(other)
    @frame_count == other.frame_count
  end

  def <=>(other)
    @frame_count - other.frame_count
  end

  # Returns difference between two SMPTEs as a SMPTE - use
  # to_i to get a frame count.
  def -(other)
    self.class.new(@frame_count - other.frame_count, @df)
  end

  def +(more_frames)
    if @has_subframes
      self.class.new(@frame_count.to_f + @subframe_count + more_frames.to_f, @df)
    else
      self.class.new(@frame_count + more_frames.to_i, @df)
    end
  end

  def to_df
    if @df=='df'
      self.copy
    else
      self.class.new(@frame_count,'df')
    end
  end

  def to_ndf
    if @df=='ndf'
      self.copy
    else
      self.class.new(@frame_count,'ndf')
    end
  end

  def compute_times
    total_frames = @frame_count
    @hours = @ten_minute_periods = @minutes = @seconds = @frames = 0
    if @df == 'df'
      # One hour of NTSC video has 107,892 instead of 108,000 frames.
      # Ten @minutes of NTSC video has 17,982 @frames instead of 18,000.
      @hours = (total_frames/107892).floor
      total_frames = total_frames % 107892
      ten_minute_periods = (total_frames/17982).floor
      total_frames = total_frames % 17982
      if total_frames >= 1800
        total_frames -= 1800
        # The first minute is a given
        @minutes = (total_frames/1798).floor + 1
        total_frames %= 1798
        if total_frames >= 28
          total_frames -= 28
          # The first second is a given
          @seconds = (total_frames/30).floor + 1
          @frames = total_frames % 30
        else
          @seconds = 0
          @frames = total_frames+2
        end
      else
        @minutes = 0
        @seconds = (total_frames/30).floor
        @frames = total_frames % 30
      end
      @minutes += ten_minute_periods * 10
    else
      @frames = total_frames % 30
      total_frames = (total_frames/30).floor
      @seconds = total_frames % 60
      total_frames = (total_frames/60).floor
      @minutes = total_frames % 60
      total_frames = (total_frames/60).floor
      @hours = total_frames
    end
  end

  private :compute_times

  # Converts to string format
  def to_s
    if @has_subframes
      sprintf("%02d:%02d:%02d%s%02d%.2f", @hours, @minutes, @seconds, (@df=='df' ? ';' : ':'), @frames, @subframes)
    elsif @has_frames
      sprintf("%02d:%02d:%02d%s%02d", @hours, @minutes, @seconds, (@df=='df' ? ';' : ':'), @frames)
    else
      sprintf("%02d:%02d:%02d", @hours, @minutes, @seconds)
    end
  end

  def to_str
    to_s
  end

  # Return the frame count
  def to_i
    if @has_subframes
      @frame_count.round
    else
      @frame_count
    end
  end

  def to_int
    to_i
  end

  def to_f
    @frame_count.to_f
  end
end
