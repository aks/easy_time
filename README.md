# EasyTime

[![CircleCI](https://circleci.com/gh/aks/easy_time.svg?style=shield)](https://app.circleci.com/pipelines/github/aks/easy_time)

Are you tired of having to deal with many kinds of date and time objects?

Are you frustrated that comparing timestamps from different systems yields
incorrect results?  _(Were you surprised to learn that, despite really good
time sync sources, many systems aren't actually synced all that closely in
time?)_

Well, then, give EasyTime a try!

`EasyTime` accepts most of the well-known date and time objects, including
`RFC2822`, `HTTPDate`, `XMLSchema`, `ISO8601`, as well as
ActiveSupport::TimeWithZone strings and provides comparisons that have an
adjustable tolerance.  With `EasyTime` methods, you can reliably compare two
timestamps and determine which one is "newer", "older" or the "same" withing
a configurable tolerance.  The default comparison tolerance is 1.minute.

In other words, if you have a time-stamp from an `ActiveRecord` object that is
a few seconds different from a related object obtained from a 3rd-party system,
(eg: AWS S3), then logically, from an application perspective, these two
objects could be considered having the "same" time-stamp.

This is quite useful when one is trying to keep state synchronized between
different systems.  How does one know if an object is "newer" or "older" than
that from another system?  If the system time from the connected systems varies
by a few or more seconds, then comparisons needs to have some tolerance.

Having a tolerant comparison makes "newness" and "oldness" checks easier to
manage across systems with possibly varying time sources.

`EasyTime` objects are just like Time objects, except:

- they auto-convert most date and time objects to Time objects
- they provide configurable tolerant comparisons between two time objects

Even if you decide to set the configurable comparison tolerance to zero
_(disabling it)_, the auto-type conversion of most date and time objects is
very useful all by itself.

Finally, this module adds a new instance method to the familiar date and time
classes, to easily convert from the object to the corresponding `EasyTime`
object:

    obj.easy_time

For example, this is pretty cool:

    '2010-09-08 07:06:05 +04:00'.easy_time # => EasyTime instance

So it is just as easy to convert an ISO8601 time string as it is to convert
a `created_at` value from an ActiveRecord object:

    rec.created_at.easy_time # => EasyTime instance

    resp = RestClient.get service_uri + '/get_time'
    time = JSON.parse(resp.body)["date_time"].easy_time


These are the currently known date and time classes the values of which will be
automatically converted, enabling tolerant ("easy") comparisons:

    Date
    Time
    DateTime
    ActiveSupport::Duration
    ActiveSupport::TimeWithZone

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem 'easy_time'
```

or, add this to your application's `*-gemspec.rb` file:

    add.dependency 'easy_time'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install easy_time

## Usage

    require 'easy_time'

### Class Methods

There are class methods and instance methods.

### Creating a `EasyTime` Value

    EasyTime.new(time)

This creates a new `EasyTime` value, which is essentially a wrapped `Time` value.

The `new` method uses the `convert` method to convert several known date and
time value types into a `Time` value.

    EasyTime.convert(timestr)

### Auto-Conversion Date and Time Classes

These are the currently known class values that can be converted:

    String                       # => Time.parse(string)
    EasyTime                     # => EasyTime.time
    Time                         # => Time
    Date                         # => Time.iso8601(Date.iso8601)
    DateTime                     # => Time.iso8601(DateTime.iso8601)
    [yyyy,mm,dd,...]             # => Time.new(yyyy,mm,dd,...)
    ActiveSupport::TimeWithZone  # => value.to_time (eg: 3.weeks.ago)
    ActiveSupport::Duration      # => Time.now + duration (eg: 2.months)

Most of the date and time classes have built-in ISO8601 formatters, which
allows easy conversion using the `Time.iso8601` parser.

The `EasyTime` and `Time` values are passed through unchanged.

The `ActiveSupport::TimeWithZone` value is converted to a `Time`.

The `ActiveSupport::Duration` value is converted to a `Time` by adding it to `Time.now`.

A `String` value is parsed with the `convert` method.

#### Time Strings

Most modern time format strings are recognized: ISO8601, RFD2822, HTTPDate,
XMLSchema, and even some natural date and time formats.  Many systems use an
[ISO8601](https://en.wikipedia.org/wiki/ISO_8601) string, which has date, time, 
and timezone components, with each variant having some variations.

With `EasyTime`, you don't have to know which time string format to use,
you can just ask `EasyTime` to convert it.  If it can't, you'll get an
`ArgumentError` exception.

### `EasyTime` Comparison Class Methods

One advantage of `EasyTime` values over the other time objects is that `EasyTime`
can perform tolerant-comparisons, where the tolerance can be specified by
you _(the developer)_.

These are the `EasyTime` class methods for comparison:

    EasyTime.newer?(t1, t2)   # => true if t1 > t2
    EasyTime.older?(t1, t2)   # => true if t1 < t2
    EasyTime.same?(t1, t2)    # => true if t1 == t2 with tolerance
    EasyTime.compare(t1, t2)  # => t1 <=> t2 => -1, 0, 1, or nil with tolerance

Each comparison method auto-converts both time arguments into a `Time` value,
and then compares them with tolerance.  This means that if the absolute
difference between `t1` and `t2` is less than the configured tolerance value,
then the two values will be considered equal _(the same)_.

If the two values are not tolerantly-equal, then the two values are compared
with `<=>`, which normally returns one of three values: [-1, 0, 1].  However,
since a tolerant-equality _(or sameness)_ was already tested and ruled out, the
comparison using `<=>` will only ever return -1 or 1.

Finally, if either time value is nil, or cannot be converted to a Time value,
the result of any comparison method is also nil.

There are other methods that make use of the tolerant comparison:

    EasyTime.between?(t1, t_min, t_max) # => true if t1 >= t_min and t1 <= t_max

or

    EasyTime.between?(t1, time_range)   # => true if t1 is within the time_range


### Configuring the Comparison Tolerance

As described above, the comparison tolerance value can be configured to
something other than the default of `DEFAULT_TIME_COMPARISON_TOLERANCE`, which
is currently set to `1.minute`.

    EasyTime.tolerance = 15.seconds # set an appropriate tolerance for our app

The above will set the tolerance value to 15 seconds.  This configuration is
applied across all instances of the class.

### EasyTime Instance Methods

Once a `EasyTime` value has been created, it is basically a wrapped `Time` value
where the comparison methods are overridden in order to apply the comparison
tolerance value.

These are the instance methods:

    t1 < t2   # => true if t1 is older than t2
    t1 > t2   # => true if t1 is newer than t2
    t1 <= t2  # => true if t1 is the same or older as t2
    t1 >= t2  # => true if t1 is the same or newer as t2
    t1 != t2  # => true if t1 is not the same as t2 (with tolerance)
    t1 == t2  # => true if t1 is the same as t2 (with tolerance)

On each of the above, the `t2` value will be automatically converted to
a `Time` value, and tolerantly compared against `t1`.

In addition to the infix operators, there are the comparison instance methods:

    t1.newer?(t2)   # => true if t1 is newer (>) than t2
    t1.older?(t2)   # => true if t1 is older (<) then t2
    t1.same?(t2)    # => true if t1 is equal (==) to t2
    t1.compare(t2)  # => [-1, 0, 1] from t1 <=> t2

and

    t1.between?(t_min, t_max)    #=> true if t_min >= t1 <= t_max
    t1.between?([t_min..t_max])  # => true if t1 is in the range

In all the above instance methods, `t2`, `t_min`, or `t_max` may be any known
date or time value, which is automatically converted into a Time value for the
tolerant comparison.

Arithmetic operators with auto-conversion are also supported:

    t1 + duration
    t1 - t2
    t1 - duration

The `t2` can be a date, time or even a time string.  In which case, the are
converted to a `Time` value, and the subtraction is performed between two
dates, with a duration result.  

When arithmetic is performed with a `duration` value, then the result is a new
updated `EasyTime` value

### Auto-Conversion Of Comparison Values

`EasyTime` values can be compared with tolerance against any other time value,
including time strings, using instance methods.  The receiver object must be an
`EasyTime` object in order to enable the auto-conversion of the other time
object.

The values provided on any comparison operator or method are converted to
a `Time` value using the same `convert` routine.  See the description of the
acceptable date and time types above.

### Comparison Tolerance Instance Methods

As given above, the comparison tolerance value used on the instance methods is
that previously configured either on the instance, or at the class level.

It is possible, however, to dynamically provide comparison tolerance when
creating a new `EasyTime` value, or with the `with_tolerance` method.

In addition to the class methods for comparison tolerance, it is possible to
configure the comparison tolerance for each instance.

The `new` method accepts an optional `tolerance:` keyword value:

    t1 = EasyTime.new(record.created_at, tolerance: 20.seconds)
    t1.newer?(another_time) # => compared with a tolerance of 20 seconds

The comparison tolerance can also be set dynamically using `.with_tolerance`:

    t1 = EasyTime.new(record.updated_at)
    t1.with_tolerance(1.second) > another_time
    t1.with_tolerance(2.seconds).newer?(another_time)

The `.with_tolerance` method creates a _new_ `EasyTime` value with the
specified tolerance, leaving the original value and configured tolerance
intact.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/aks/easy_time.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

Alan K. Stebbens `<aks@stebbens.org>`
