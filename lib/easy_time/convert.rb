# frozen_string_literal: true

# These class methods are for converting most date or time formats to a Time
class EasyTime
  class << self
    # convert(time) converts most date and time objects or strings into a Time object
    #
    # convert()                  # => Time.now
    # convert(String)            # => detect time style and parse accordingly
    # convert(EasyTime)          # => EasyTime.time
    # convert(Time)              # => Time
    # convert(Date)              # => Time.iso8601(Date.iso8601)
    # convert(DateTime)          # => Time.iso8601(DateTime.iso8601)
    # convert([yyyy,mm,dd,...])  # => Time.new(yyyy,mm,dd,...)
    # convert(3.weeks.ago)       # => value.to_time        [ActiveSupport::TimeWithZone]
    # convert(2.months)          # => Time.now + duration  [ActiveSupport::Duration]
    #
    # When a string is used as an argument, it is examined for several date-time patterns
    # and a corresponding parser is used; when all else fails, `Time.parse` is used.
    #
    # The following time format patterns are checked:
    #   rfc2822   - used in Emails
    #   httpdate  - used in web logs      (a variant of rfc822, with symbolic timezones)
    #   xmlschema - used in XML schemas   (a strict subset of iso8601)
    #   iso8601   - used in many systems
    #
    # Time/Date string examples:
    #     httpdate:      Thu, 06 Oct 2011 02:26:12 GMT
    #     rf2822:        Wed, 05 Oct 2011 22:26:12 -0400
    #     xmlschema:     2011-10-05T22:26:12-04:00
    #     xmlschema:     YYYY-MM-DD or YYYYMMDD
    #     iso8601:       CCYY-MM-DDThh:mm:ss.sssTZD
    #     iso8601 date:  YYYY-MM  YYYY-DDD or YYYYDDD or YYYYMMDD
    #     iso8601 time:  hh:mm:ss.ssss or hhmmss.sss or hh:mm:ss or hh:mm or hhmmss or hhmm or hh
    #     iso8601 zone:  Z or +-HH:MM or +-HHMM
    #
    # When an Integer or Float is used a time value, it is passed to `Time.at`, which interprets
    # the value as being the number of seconds since the Epoch (1970).

    # @param arg [String, EasyTime, Time, Date, DateTime, Array<Integer>, Duration]
    #             various kinds of date and time values
    # @param coerce [Boolean] if true, coerce the `arg` into a Time object _(default: true)_
    # @return [Time]
    def convert(arg, coerce = true)
      case arg
      when String
        parse_string(arg)              # parse the string value into an EasyTime object
      when Array
        ::Time.new(*arg)               # convert Time arguments: [yyyy, mm, dd, hh, MM, SS]
      when ::EasyTime
        arg.time                       # extract the EasyTime value
      when ActiveSupport::TimeWithZone
        arg.to_time                    # convert the TimeWithZone value to a Time object
      when ActiveSupport::Duration
        coerce ? Time.now + arg : arg  # coerced duration objects are relative to "now"
      when ::Time
        arg                            # accept Time objects as-as
      when ::Date, ::DateTime
        ::Time.iso8601(arg.iso8601)    # convert Date and DateTime objects via ISO8601 formatting
      when NilClass
        ::Time.now                     # a nil object means "now"
      when Numeric
        coerce ? Time.at(arg) : arg   # if coerced, treat as seconds-since-Epoch
      else
        raise ArgumentError, "EasyTime: unknown value: '#{arg.inspect}'"
      end
    end

    private

    def parse_string(time_str)
      parser = time_format_style(time_str)
      # invoke the found parser format, otherwise use the fall-back general-purpose parser
      (parser && ::Time.send(parser, time_str) rescue nil) || ::Time.parse(time_str)
    end

    public

    # A regexp pattern to match the date part of an ISO8601 time string
    ISO_DATE_RE = /(?: \d{4}-\d\d-\d\d  # yyyy-mm-dd
                     | \d{4}-\d\d       # yyyy-mm
                     | \d{4}-\d{3}      # yyyy-ddd
                     | \d{7,8}          # yyyymmdd  or yyyyddd
                     | --\d\d-?\d\d     # --mm-dd or --mmdd
                   )
                  /x.freeze

    # A regexp pattern to match the time part of an ISO8601 time string
    ISO_TIME_RE = /(?:
                     (?:
                       (?: \d\d:\d\d:\d\d  # hh:mm:ss
                         | \d{6}           # hhmmss
                       )
                       (?: \.\d+ )?        # optional .sss
                     )
                     | \d\d:?\d\d          # hh:mm or hhmm
                     | \d{2}               # hh
                   )
                  /x.freeze

    # A regexp pattern to match the timezone part of an ISO8601 time string
    ISO_ZONE_RE = /(?: Z                # Z for zulu (GMT = 0)
                     | [+-] \d\d:?\d\d  # +-HH:MM or +-HHMM
                   )
                  /x.freeze

    # A regexp pattern to match an ISO8601 time string.
    # @see https://en.wikipedia.org/wiki/ISO_8601
    ISO8601_RE = / #{ISO_DATE_RE} T #{ISO_TIME_RE} #{ISO_ZONE_RE} /x.freeze

    # A regexp pattern to match an RFC2822 time string _(used in Email messages and systems)_
    RFC2822_RE = /\w{3},         \s  # Wed,
                  \d{1,2}        \s  # 01 or 1
                  \w{3}          \s  # Oct
                  \d{4}          \s  # 2020
                  \d\d:\d\d:\d\d \s  # HH:MM:SS
                  [+-]\d\d:?\d\d     # +-HH:MM or +-HHHMM (zone)
                 /x.freeze

    # A regexp pattern to match an HTTPDate time string _(used in web server transactions and logs)_
    HTTPDATE_RE = /\w{3},         \s  # Wed,
                   \d{1,2}        \s  # 01 or 1
                   \w{3}          \s  # Oct
                   \d{4}          \s  # 2020
                   \d\d:\d\d:\d\d \s  # HH:MM:SS
                   \w+                # GMT
                  /x.freeze

    # A regexp pattern to match an XMLSchema time string _(used in XML documents)_
    XMLSCHEMA_RE = /\d{4}-\d\d-\d\d   # yyyy-mm-dd
                    T
                    \d\d:\d\d:\d\d    # HH:MM:SS
                    [+-]              # +-
                    \d\d:\d\d         # HH:MM
                   /x.freeze

    # this method returns parser class methods in the Time class for
    # corresponding time format patterns
    def time_format_style(str)
      case str
      when RFC2822_RE   then :rfc2822
      when HTTPDATE_RE  then :httpdate
      when XMLSCHEMA_RE then :xmlschema
      when ISO8601_RE   then :iso8601
      end
    end
  end
end
