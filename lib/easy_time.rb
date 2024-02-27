# frozen_string_literal: true

require 'time'
require 'date'
require 'active_support'
require 'active_support/duration'
require 'active_support/time_with_zone'
require 'active_support/core_ext/numeric/time'

require 'easy_time/version'
require 'easy_time/convert'

# Are you tired of having to deal with many kinds of date and time objects?
#
# Are you frustrated that comparing timestamps from different systems yields
# incorrect results?  _(Were you surprised to learn that, despite really good
# time sync sources, many systems aren't actually synced all that closely in
# time?)_
#
# Well, then, give EasyTime a try!
#
# `EasyTime` accepts most of the well-known date and time objects, including
# `RFC2822`, `HTTPDate`, `XMLSchema`, and `ISO8601` strings and provides
# comparisons that have an adjustable tolerance.  With `EasyTime` methods, you
# can reliably compare two timestamps and determine which one is "newer", "older"
# or the "same" withing a configurable tolerance.
#
# The default comparison tolerance is 1 second.  This means that if a local
# object is created at time t1 and then transferred across the network and used
# to create a corresponding object in a 3rd-party system, eg: AWS S3, at time
# t2, then if `(t1 - t2).abs` is < 1.second the two times would be logicall the
# same.
#
# In other words, if you have a time-stamp from an `ActiveRecord` object that
# is a few milliseconds different from a related object obtained from a
# 3rd-party system, (eg: AWS S3), then logically, from an application
# perspective, these two objects could be considered having the "same"
# time-stamp.
#
# This is quite useful when one is trying to keep state synchronized between
# different systems.  How does one know if an object is "newer" or "older" than
# that from another system?  If the system time from the connected systems
# varies by a few or more seconds, then comparisons needs to have some
# tolerance.
#
# Having a tolerant comparison makes "newness" and "oldness" checks easier to
# manage across systems with possibly varying time sources.
#
# However, it is also important to keep the tolerance as small as possible in
# order to avoid causing more problems, such as false equivalences when objects
# really were created at different moments in time.
#
# `EasyTime` objects are just like Time objects, except:
#
# - they auto-convert most time objects, including strings, to Time objects
# - they provide configurable tolerant comparisons between two time objects
#
# Even if you decide to set the configurable comparison tolerance to zero
# _(which disables it)_, the auto-type conversion of most date and time objects
# makes time and date comparisons and arithmetic very easy.
#
# Finally, this module adds an new instance method to the familiar date and
# time classes, to easily convert from the object to the corresponding
# `EasyTime` object:
#
#     time.easy_time
#
# The conversion to an `EasyTime` can also be provided with a tolerance value:
#
#     time.easy_time(tolerance: 2.seconds)
#
# These are the currently known date and time classes the values of which will
# be automatically converted to an `EasyTime` value with tolerant comparisons:
#
#     Date
#     Time
#     EasyTime
#     DateTime
#     ActiveSupport::Duration
#     ActiveSupport::TimeWithZone
#     String
#
# The String values are examined and parsed into a `Time` value.  If a string
# cannot be parsed, the `new` and `convert` methods return a nil.
#
class EasyTime
  include Comparable

  # we define a default tolerance below.  This causes time value differences
  # less than this to be considered "equal".  This allows for time comparisons
  # between values from different systems where the clock sync might not be
  # very accurate.
  #
  # If this default tolerance is not desired, it can be overridden with an
  # explicit tolerance setting in the singleton class instance:
  #
  #   EasyTime.comparison_tolerance = 0

  DEFAULT_TIME_COMPARISON_TOLERANCE = 1.second

  class << self
    # @example These comparison methods observe the comparison tolerance
    #
    #    EasyTime.newer?(t1, t2, tolerance: nil)  # => true if t1 > t2
    #    EasyTime.older?(t1, t2, tolerance: nil)  # => true if t1 < t2
    #    EasyTime.same?(t1, t2, tolerance: nil)   # => true if t1 == t2
    #    EasyTime.compare(t1, t2, tolerance: nil) # => -1, 0, 1 (or nil)
    #
    #  By default, the `tolerance` is nil, which means that any previously
    #  configured instance comparison tolerance value is used, if it is set,
    #  otherwise, the class comparison tolerance is used, if it set, otherwise
    #  the default `DEFAULT_TIME_COMPARISON_TOLERANCE` is used.

    # @param time1 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] a time value
    # @param time2 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] another time value
    # @param tolerance [Integer] seconds of tolerance _(optional)_
    # @return [Boolean] true if `time1` > `time2`, using a tolerant comparison

    def newer?(time1, time2, tolerance: nil)
      compare(time1, time2, tolerance: tolerance).positive?
    end

    # @param time1 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] a time value
    # @param time2 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] another time value
    # @param tolerance [Integer] seconds of tolerance _(optional)_
    # @return [Boolean] true if `time1` > `time2`, using a tolerant comparison

    def older?(time1, time2, tolerance: nil)
      compare(time1, time2, tolerance: tolerance).negative?
    end

    # @param time1 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] a time value
    # @param time2 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] another time value
    # @param tolerance [Integer] seconds of tolerance _(optional)_
    # @return [Boolean] true if `time1` > `time2`, using a tolerant comparison

    def same?(time1, time2, tolerance: nil)
      compare(time1, time2, tolerance: tolerance).zero?
    end

    # @overload between?(time1, t_min, t_max, tolerance: nil)
    #   @param time1 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] a time value
    #   @param t_min [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] the minimum time
    #   @param t_max [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] the maximum time
    #   @return [Boolean] true if `t_min <= time1 <= t_max`, using tolerant comparisons
    #
    # @overload between?(time1, time_range, tolerance: nil)
    #   @param time1 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] a time value
    #   @param time_range [Range] a range `(t_min..t_max)` of time values
    #   @return [Boolean] true if `time_range.min <= time1 <= time_range.max`, using tolerant comparisons

    def between?(time1, t_arg, t_max = nil, tolerance: nil)
      if t_arg.is_a?(Range)
        t_min = t_arg.min
        t_max = t_arg.max
      else
        t_min = t_arg
      end
      compare(time1, t_min, tolerance: tolerance) >= 0 &&
        compare(time1, t_max, tolerance: tolerance) <= 0
    end

    # @param time1 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] a time value
    # @param time2 [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] another time value
    # @param tolerance [Integer] seconds of tolerance _(optional)_
    # @return [Integer] one of [-1, 0, 1] if `time1` <, ==, or > than `time2`,
    #         or nil if `time2` cannot be converted to a `Time` value.

    def compare(time1, time2, tolerance: nil)
      new(time1, tolerance: tolerance) <=> time2
    end

    # These methods make it easy to add or subtract dates and durations
    #     EasyTime.add(time, duration, tolerance: nil)
    #     EasyTime.subtract(time, time_or_duration, tolerance: nil)

    # @param time [Time,DateTime,ActiveSupport::TimeWithZone,Date,String,Integer,Array<Integer>] a time value
    # @param duration [ActiveSupport::Duration,Integer,Float] a duration value
    # @return [EasyTime] the `time` with the `duration` added

    def add(time, duration)
      EasyTime.new(time) + duration
    end

    # @param time [Time,DateTime,ActiveSupport::TimeWithZone,Date,String,Integer,Array<Integer>] a time value
    # @param time_or_duration [Time,DateTime,ActiveSupport::Duration,Integer,Float] a time or duration value
    # @return [EasyTime,Duration] an `EasyTime` value, when a duration is subtracted from a time, or
    #         a duration _(Integer)_ value, when one time is subtracted from another time.

    def subtract(time, time_or_duration)
      EasyTime.new(time) - time_or_duration
    end

    attr_writer :comparison_tolerance

    # Class methods to set the class-level comparison tolerance
    #
    # @example
    #     EasyTime.comparison_tolerance = 0          # turns off any tolerance
    #     EasyTime.comparison_tolerance = 5.seconds  # makes times within 5 seconds the "same"
    #     EasyTime.comparison_tolerance = 1.minute   # the default

    # @return [Integer] the number of seconds of tolerance to use for "equality" tests
    def comparison_tolerance
      @tolerance || DEFAULT_TIME_COMPARISON_TOLERANCE
    end

    # @param time_string [String] a time string in one of the many known Time string formats
    # @return [EasyTime]
    def parse(time_string)
      new(parse_string(time_string))
    end

    def method_missing(symbol, *args, &block)
      if Time.respond_to?(symbol)
        value = Time.send(symbol, *args, &block)
        is_a_time?(value) ? new(value) : value
      else
        super(symbol, *args, &block)
      end
    end

    def respond_to_missing?(symbol, include_all = false)
      Time.respond_to?(symbol, include_all)
    end

    # @param value [Anything] value to test as a time-like object
    # @return [Boolean] true if value is one the known Time classes, or responds to :acts_like_time?
    def a_time?(value)
      case value
      when Integer, ActiveSupport::Duration
        false
      when Date, Time, DateTime, ActiveSupport::TimeWithZone, EasyTime
        true
      else
        value.respond_to?(:acts_like_time?) && value.acts_like_time?
      end
    end
    alias is_a_time? a_time?
  end

  attr_accessor :time
  attr_reader   :other_time
  attr_writer   :comparison_tolerance

  delegate :to_s, :inspect, to: :time

  def initialize(*time, tolerance: nil)
    @time = time.size.nonzero? && convert(time.size == 1 ? time.first : time)
    @comparison_tolerance = tolerance
  end

  # if there is no instance value, default to the class value
  def comparison_tolerance
    @comparison_tolerance || self.class.comparison_tolerance
  end

  # returns a _new_ EasyTime value with the tolerance set to value
  #
  # @example Example:
  #
  #    t1 = EasyTime.new(some_time)
  #    t1.with_tolerance(2.seconds) <= some_other_time
  #
  # @param value [Integer] a number of seconds to use as the comparison tolerance
  # @return [EasyTime] a new EasyTime value with the given tolerance

  def with_tolerance(value)
    dup.tap { |time| time.comparison_tolerance = value }
  end

  # @example Comparison examples
  #    time1 = EasyTime.new(a_time, tolerance: nil)
  #    time1.newer?(time2)
  #    time1.older?(time2)
  #    time1.same?(time2)
  #    time1.compare(time2) # => -1, 0, 1

  # @param time2 [String,Date,Time,DateTime,Duration,Array<Integer>] another time value
  # @return [Boolean] true if `self` > `time2`

  def newer?(time2)
    self > time2
  end

  # @param time2 [String,Date,Time,DateTime,Duration,Array<Integer>] another time value
  # @return [Boolean] true if `self` < `time2`

  def older?(time2)
    self < time2
  end

  # @param time2 [String,Date,Time,DateTime,Duration,Array<Integer>] another time value
  # @return [Boolean] true if `self` == `time2`

  def same?(time2)
    self == time2
  end
  alias eql? same?

  # @param time2 [String,Date,Time,DateTime,Duration,Array<Integer>] another time value
  # @return [Boolean] true if `self` != `time2`

  def different?(time2)
    self != time2
  end

  # @param time2 [String,Date,Time,DateTime,Duration,Array<Integer>] another time value
  # @return [Integer] one of the values: [-1, 0, 1] if `self` [<, ==, >] `time2`,
  #         or nil if `time2` cannot be converted to a `Time` value

  def compare(time2, tolerance: nil)
    self.comparison_tolerance = tolerance if tolerance
    self <=> time2
  end

  # compare with automatic type-conversion and tolerance
  # @return [Integer] one of [-1, 0, 1] or nil

  def <=>(other)
    diff = self - other  # NOTE: this has a side-effect of setting @other_time
    if diff && diff.to_i.abs <= comparison_tolerance.to_i
      0
    elsif diff
      time <=> other_time
    end
  end

  # compare a time against a min and max date pair, or against a time Range value.
  # @overload between?(t_min, t_max, tolerance: nil)
  #   @param t_min [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] the minimum time
  #   @param t_max [Date,Time,DateTime,EasyTime,Duration,String,Array<Integer>] the maximum time
  #   @param tolerance [Integer] the optional amount of seconds of tolerance to use in the comparison
  #   @return [Boolean] true if `t_min <= self.time <= t_max`, using tolerant comparisons
  #
  # @overload between?(time_range, tolerance: nil)
  #   @param time_range [Range] a range `(t_min..t_max)` of time values
  #   @param tolerance [Integer] the optional amount of seconds of tolerance to use in the comparison
  #   @return [Boolean] true if `time_range.min <= self.time <= time_range.max`, using tolerant comparisons

  def between?(t_arg, t_max = nil)
    if t_arg.is_a?(Range)
      t_min = t_arg.min
      t_max = t_arg.max
    else
      t_min = t_arg
    end
    compare(t_min) >= 0 && compare(t_max) <= 0
  end

  # @param duration [Integer] seconds to add to the EasyTime value
  # @return [EasyTime] updated date and time value
  def +(duration)
    dup.tap { |eztime| eztime.time += duration }
  end

  # Subtract a value from an EasyTime.  If the value is an integer, it is treated
  # as seconds.  If the value is any of the Date, DateTime, Time, EasyTime, or a String-
  # formatted date/time, it is subtracted from the EasyTime value resulting in an integer
  # duration.
  # @param other [Date,Time,DateTime,EasyTime,Duration,String,Integer]
  #        a date/time value, a duration, or an Integer
  # @return [EasyTime,Integer] updated time _(time - duration)_ or duration _(time - time)_
  def -(other)
    @other_time = convert(other, coerce: false)
    if is_a_time?(other_time)
      time - other_time
    elsif other_time
      dup.tap { |eztime| eztime.time -= other_time }
    end
  end

  def acts_like_time?
    true
  end

  private

  def convert(datetime, coerce: true)
    self.class.convert(datetime, coerce: coerce)
  end

  # intercept any time methods so they can wrap the time-like result in a new EasyTime object.
  def method_missing(symbol, *args, &block)
    if time.respond_to?(symbol)
      value = time.send(symbol, *args, &block)
      is_a_time?(value) ? dup.tap { |eztime| eztime.time = value } : value
    else
      super(symbol, *args, &block)
    end
  end

  def respond_to_missing?(symbol, include_all = false)
    time.respond_to?(symbol, include_all)
  end

  def a_time?(value)
    self.class.is_a_time?(value)
  end
  alias is_a_time? a_time?
end

# Extend the known date and time classes _(including EasyTime itself!)_
module EasyTimeExtensions
  def easy_time(tolerance: nil)
    EasyTime.new(self, tolerance: tolerance)
  end
end

[EasyTime, Date, Time, DateTime, ActiveSupport::Duration, ActiveSupport::TimeWithZone, String].each do |klass|
  klass.include(EasyTimeExtensions)
end

# end of EasyTime
