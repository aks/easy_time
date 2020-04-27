# frozen_string_literal: true

require 'spec_helper'
require 'easy_time'

RSpec.describe EasyTime do
  EASY_TIME_DATA =
    [ #  date1,                      date2                        <=>
      ['2010-04-15T09:13:19-05:00',  '2010-04-15T09:13:19-05:00',  0],
      ['2011-04-15T09:13:20-05:00',  '2011-04-15T09:13:25-05:00',  0],
      ['2012-04-15T09:13:20-05:00',  '2012-04-15T09:14:22-05:00', -1],
      ['2013-04-14T09:13:20-05:00',  '2013-04-15T09:13:20-05:00', -1],
      ['2014-04-15T09:13:20-05:00',  '2014-04-14T09:13:20-05:00', +1],
      ['2015-04-15T09:13:20-07:00',  '2015-04-15T09:13:20-05:00', +1],
      ['2016-04-15T09:13:20-00:00',  '2016-04-15T09:13:20-05:00', -1],
      ['2017-04-15T09:13:20-00:00',  '2017-04-15T09:13:21-00:00',  0],
      ['2018-04-15T09:13:20-00:00',  '2018-04-15T09:14:20-00:00',  0],
      ['2019-04-15T09:13:20-00:00',  '2019-04-15T09:14:21-00:00', -1],
      ['2020-04-15T09:13:20-00:00',  '2020-04-15T09:13:24-00:00',  0],
      ['2021-04-15T09:13:20-00:00',  '2021-04-15T09:14:21-00:00', -1]
    ]

  TEST_BETWEEN_VALUES = [
    # tmin,                        tmax,                      result
    ['2010-09-08 07:06:05 -05:00', '2010-09-08 15:06:05 GMT', false], # t_min = 12:06:05 GMT
    ['2010-09-08 07:06:05 -04:00', '2010-09-08 15:06:05 GMT', true ], # t_min = 11:06:05 GMT
    ['2010-09-08 07:06:05 -03:00', '2010-09-08 15:06:05 GMT', true ], # t_min = 10:06:05 GMT
    ['2010-09-08 07:06:05 -02:00', '2010-09-08 15:06:05 GMT', true ], # t_min =  9:06:05 GMT
    ['2010-09-08 07:06:06 -04:00', '2010-09-08 15:06:05 GMT', true ], # t_min = 11:06:06 GMT
    ['2010-09-08 07:06:07 -04:00', '2010-09-08 15:06:05 GMT', false], # t_min = 11:06:07 GMT
    ['2010-09-08 07:06:05 -04:00', '2010-09-08 11:06:05 GMT', true ], # t_max = 11:06:05 GMT
    ['2010-09-08 07:06:05 -04:00', '2010-09-08 11:06:04 GMT', true ], # t_max = 11:06:04 GMT
    ['2010-09-08 07:06:05 -04:00', '2010-09-08 11:06:03 GMT', false], # t_max = 11:06:03 GMT
  ]

  shared_examples_for 'easy time comparisons' do |method|
    describe ".#{method}" do
      EASY_TIME_DATA.each do |data_row|
        time1, time2, compare_result = data_row
        context "..with time1 as #{time1}" do
          let(:test_time1) { time1 }

            context "with time2 as #{time2}" do
            subject { EasyTime.send(method, test_time1, test_time2) }
            let(:test_time2) { time2 }
            let(:expected_result) do
              case method
              when :newer?  then compare_result > 0
              when :same?   then compare_result == 0
              when :older?  then compare_result < 0
              when :compare then compare_result
              end
            end
            it { is_expected.to eq expected_result }
          end
        end
      end
    end
  end

  context 'class methods' do
    it_behaves_like 'easy time comparisons', :newer?
    it_behaves_like 'easy time comparisons', :older?
    it_behaves_like 'easy time comparisons', :same?
    it_behaves_like 'easy time comparisons', :compare
  end

  context 'new conversions' do
    EASY_TIME_DATA.each do |(time1, time2, compare)|
      context "using times '#{time1}' and '#{time2}'" do
        rfc2822_str1  = Time.iso8601(time1).rfc2822
        rfc2822_str2  = Time.iso8601(time2).rfc2822
        rfc2822_time1 = Time.rfc2822(rfc2822_str1)
        rfc2822_time2 = Time.rfc2822(rfc2822_str2)

        let(:test_time1_str)  { rfc2822_str1 }
        let(:test_time2_str)  { rfc2822_str2 }

        let(:rfc2822_time1) { Time.rfc822(rfc2822_str1) }
        let(:rfc2822_time2) { Time.rfc822(rfc2822_str2) }

        [[rfc2822_str1, rfc2822_time1],
         [rfc2822_str2, rfc2822_time2]].each do |(str, result)|
          context "with an RFC2822 time string as '#{str}'" do
            subject { EasyTime.convert(str) }
            it { is_expected.to eq result }

            context "with a second RFC2822 time string as '#{rfc2822_str2}'" do
              subject { EasyTime.compare(test_time1_str, test_time2_str) }
              it { is_expected.to eq compare }
            end
          end
        end
      end
    end
  end

  describe '.between?' do
    let(:tolerance) { 1.second }
    let(:time) { '2010-09-08 07:06:05 -04:00' }

    TEST_BETWEEN_VALUES.each do |t_min, t_max, result|
      context "with a pair of times: #{t_min} and #{t_max}" do
        subject { EasyTime.between?(time, t_min, t_max, tolerance: tolerance) }
        let(:t_min) { t_min }
        let(:t_max) { t_max }
        it { is_expected.to eq result }
      end

      context 'with a time range' do
        subject { EasyTime.between?(time, time_range, tolerance: tolerance) }
        let(:time_range) { (EasyTime.new(t_min)..EasyTime.new(t_max)) }
        it { is_expected.to eq result }
      end
    end
  end

  describe '.convert' do
    subject { EasyTime.convert(test_arg, coerce_it) }

    let(:coerce_it) { true }

    context 'with an ActiveSupport::TimeWithZone value' do
      around do |ex|
        old_zone = Time.zone
        Time.zone = 'Hawaii'
        ex.run
        Time.zone = old_zone
      end

      let(:test_arg) { Time.zone.parse(time_string) }
      let(:time_string) { '2010-09-08 07:06:05' }

      it { is_expected.to be_a(Time) }

      it 'has the correct time' do
        expect(subject.utc.to_s).to eq '2010-09-08 17:06:05 UTC'
      end
    end

    context 'with a nil value' do
      let(:test_arg) { nil }

      it { is_expected.to be_a(Time) }

      it 'should be the "now" time' do
        expect(EasyTime.new(subject)).to eq EasyTime.now
      end
    end

    context 'with a number' do
      context 'with coercion' do
        let(:test_arg) { Time.now.to_i }

        it { is_expected.to be_a(Time) }

        it 'should be the time based on seconds since the Epoch' do
          expect(subject.to_i).to eq test_arg.to_i
        end
      end

      context 'without coercion' do
        let(:test_arg) { (2.weeks).to_i }
        let(:coerce_it) { false }

        it { is_expected.to be_a(Numeric) }
        it { is_expected.to eq test_arg }
      end
    end

    context 'with a Duration' do
      let(:test_arg) { 2.weeks }

      context 'with coercion' do
        it { is_expected.to be_a(Time) }

        it 'should be an offset from now' do
          expect(EasyTime.new(subject)).to eq (EasyTime.now + test_arg)
        end
      end

      context 'without coercion' do
        let(:coerce_it) { false }
        let(:test_arg) { 2.weeks }

        it { is_expected.to be_a(ActiveSupport::Duration )}
        it { is_expected.to eq test_arg }
      end
    end

    context 'with an unknown type' do
      let(:test_arg) { /a-regexp/ }

      it "raises an error" do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".parse" do
    subject { EasyTime.parse(time_str) }

    shared_examples_for 'parse' do |kind, time_str|
      context "with #{kind} time string of #{time_str}" do
        let(:time_str) { time_str }

        it "creates an EasyTime time" do
          expect(subject).to be_an(EasyTime)
        end

        it 'parses the time correctly' do
          expect(subject).to eq Time.parse(time_str)
        end
      end
    end

    it_behaves_like 'parse', :iso8601,   "2010-09-08T07:06:05-04:00"
    it_behaves_like 'parse', :iso8601,   "20100908T070605-04:00"
    it_behaves_like 'parse', :rfc2822,   "Sun, 26 Apr 2020 12:43:00 -05:00"
    it_behaves_like 'parse', :httpdate,  "Sun, 26 Apr 2020 12:43:00 GMT"
    it_behaves_like 'parse', :xmlschema, "2010-09-08T07:06:05-04:00"
    it_behaves_like 'parse', :natural,   "12:49:00AM, Sunday, April 26, 2020"
    it_behaves_like 'parse', :natural,   "26-April-2020 12:49:00 CDT"
  end

  describe "#missing_method" do
    context 'using known Time class methods' do
      context 'using iso8601' do
        subject { EasyTime.iso8601(time_string) }

        let(:time_string) { "2020-10-09T08:07:06-05:00" }

        it "invokes the same method on the Time class" do
          expect(Time).to receive(:iso8601).and_call_original
          subject
        end

        it { is_expected.to be_an(EasyTime) }

        it 'parses the correct value' do
          expect(subject.time).to eq Time.parse(time_string)
        end
      end

      context 'using now' do
        subject { EasyTime.now }

        it { is_expected.to be_an(EasyTime) }

        it 'invokes the same method on the Time class' do
          expect(Time).to receive(:now).and_call_original
          subject
        end

        it 'produces now' do
          expect(subject.time.iso8601).to eq Time.now.iso8601
        end
      end
    end

    context 'using unknown Time class methods' do
      subject { EasyTime.whut? }

      it 'raises an error' do
        expect { subject }.to raise_error(NoMethodError)
      end
    end
  end

  describe '.respond_to_missing?' do
    subject { EasyTime.respond_to?(test_name) }

    context 'with a known Time method' do
      let(:test_name) { :utc }

      it 'invokes the respond_to? on the Time class with method name as the argument' do
        expect(Time).to receive(:respond_to?).with(test_name, boolean)
        subject
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context 'with an unknown Time method' do
      let(:test_name) { :whut? }

      it 'invokes respond_to? on the Time class' do
        expect(Time).to receive(:respond_to?).with(test_name, boolean)
        subject
      end

      it 'returns false' do
        expect(subject).to be false
      end
    end
  end

  context 'instance methods' do
    describe '#new' do
      shared_examples_for 'new' do |arg, tolerance, result|
        context "with arg #{arg} and #{tolerance} tolerance" do
          subject do
            if tolerance && arg.is_a?(Array)
              EasyTime.new(*arg, tolerance: tolerance)
            elsif tolerance
              EasyTime.new(arg, tolerance: tolerance)
            elsif arg.is_a?(Array)
              EasyTime.new(*arg)
            else
              EasyTime.new(arg)
            end
          end

          it "converts the argument to a Time value" do
            expect(EasyTime).to receive(:convert).with(arg, true).and_call_original
            expect(subject.time).to be_a(Time)
          end

          it "stores the tolerance value in the instance variable" do
            expect(subject.instance_variable_get(:@comparison_tolerance)).to eq tolerance
          end

          it "converts the value properly" do
            expect(subject.iso8601).to eq result
          end
        end
      end

      it_behaves_like 'new', '2010-04-15T09:13:19-05:00', nil, '2010-04-15T09:13:19-05:00'
      it_behaves_like 'new', '2011-04-15T09:13:20-08:00', 7,   '2011-04-15T09:13:20-08:00'

      date_time = DateTime.parse('2012-04-15T09:13:20-07:00')
      it_behaves_like 'new', date_time, 5, '2012-04-15T09:13:20-07:00'

      time = Time.parse('2013-03-15T09:12:19-05:00')
      it_behaves_like 'new', time, nil, '2013-03-15T09:12:19-05:00'

      time_args = [2014, 5, 15, 9, 12, 19, "-05:00"]
      it_behaves_like 'new', time_args, 20, '2014-05-15T09:12:19-05:00'
    end

    describe '#<=>' do
      EASY_TIME_DATA.each do |time1, time2, result|
        context "with time1 #{time1} and EasyTime" do
          subject { EasyTime.new(time1) <=> EasyTime.new(time2) }
          it { is_expected.to eq result }
        end

        context 'with auto-conversion of the second argument' do
          context "with time1 #{time1} and string #{time2}" do
            subject { EasyTime.new(time1) <=> time2 }
            it { is_expected.to eq result }
          end

          context "with time1 #{time1} and DateTime #{time2}" do
            subject { EasyTime.new(time1) <=> DateTime.parse(time2) }
            it { is_expected.to eq result }
          end
        end
      end
    end

    describe '#between?' do
      let(:eztime) { EasyTime.new('2010-09-08 07:06:05 -04:00') } # 11:06:05 GMT
      let(:tolerance) { 1.second }

      context 'with a min, max pair of time values' do
        subject { eztime.with_tolerance(tolerance).between?(t_min, t_max) }

        TEST_BETWEEN_VALUES.each do |t_min, t_max, result|
          context "with t_min: #{t_min}" do
            let(:t_min) { t_min }
            context "with t_max: #{t_max}" do
              let(:t_max) { t_max }
              it { is_expected.to be result }
            end
          end
        end
      end

      context 'with a Range of times value' do
        subject { eztime.with_tolerance(tolerance).between?(time_range) }

        TEST_BETWEEN_VALUES.each do |t_min, t_max, result|
          range = (t_min..t_max)
          context "with range #{range}" do
            let(:time_range) { range }
            it { is_expected.to be result }
          end
        end
      end
    end

    describe ':+' do
      subject { eztime + duration }

      let(:eztime)   { EasyTime.new("2020-10-9T08:07:06-05:00") }
      let(:duration) { 3.days + 2.hours + 1.second }

      it "returns an EasyTime value" do
        expect(subject).to be_a(EasyTime)
      end

      it "adds seconds to the time value" do
        expect(subject - eztime).to be > 3.days
      end
    end

    describe ':-' do
      subject { eztime - other }

      let(:eztime) { EasyTime.new("2020-10-9T08:07:06-05:00") }

      context 'subtracting date/times' do
        context "when the other time is a string date" do
          let(:other) { EasyTime.new("2020-10-9T08:07:05-05:00") }
          it { is_expected.to eq 1 }
        end

        context "when the other time is a larger string date" do
          let(:other) { EasyTime.new("2020-10-9T08:07:07-05:00") }
          it { is_expected.to eq(-1) }
        end

        context "when the other time is a smaller Time" do
          let(:other) { Time.parse("2020-10-9T08:07:04-05:00") }
          it { is_expected.to eq 2 }
        end

        context "when the other time is another larger EasyTime" do
          let(:other) { EasyTime.new("2020-10-9T08:07:08-05:00") }
          it { is_expected.to eq(-2) }
        end
      end

      context 'subtracting a duration' do
        subject { eztime - duration }

        context 'with a duration of an hour' do
          let(:duration) { 1.hour }
          it { is_expected.to eq EasyTime.new("2020-10-9T07:07:06-05:00") }
        end

        context 'with a duration of minutes' do
          let(:duration) { 5.minutes }
          it { is_expected.to eq EasyTime.new("2020-10-9T08:02:06-05:00") }
        end

        context 'with a duration of hours, minutes, and seconds' do
          let(:duration) { 1.hour + 2.minutes + 3.seconds }
          it { is_expected.to eq EasyTime.new("2020-10-9T07:05:03-05:00") }
        end
      end
    end

    describe 'with_tolerance' do
      subject { eztime1.with_tolerance(tolerance).same?(eztime2) }
      let(:eztime1)  { EasyTime.new("2020-10-09T08:07:06-05:00") }
      let(:tolerance) { 1.minute }

      context 'within tolerance' do
        let(:eztime2) { eztime1 + 1.minute }

        it { is_expected.to be true }
      end

      context 'not within tolerance' do
        let(:eztime2) { eztime1 + 1.minute + 1.second }

        it { is_expected.to be false }
      end
    end


    describe 'comparison methods and operators' do
      shared_examples_for 'comparison operators' do |convert, time1, time2, result|
        context "with time1 #{time1} and time2 #{time2} #{convert ? ' and conversion' : ''}" do

          let(:eztime1) { EasyTime.new(time1) }
          let(:eztime2) { convert ? EasyTime.new(time2) : time2 }

          let(:newer) { result >  0 }
          let(:same)  { result == 0 }
          let(:older) { result <  0 }

          context 'testing compare' do
            subject { eztime1.compare(eztime2) }
            it { is_expected.to eq result }
          end

          context 'testing newer?' do
            subject { eztime1.newer?(eztime2) }
            it { is_expected.to eq newer }
          end

          context 'testing same?' do
            subject { eztime1.same?(eztime2) }
            it { is_expected.to eq same }
          end

          context 'testing different?' do
            subject { eztime1.different?(eztime2) }
            it { is_expected.to eq !same }
          end

          context 'testing older?' do
            subject { eztime1.older?(eztime2) }
            it { is_expected.to eq older }
          end

          context 'testing <' do
            subject { eztime1 < eztime2 }
            it { is_expected.to eq older }
          end

          context 'testing ==' do
            subject { eztime1 == eztime2 }
            it { is_expected.to eq same }
          end

          context 'testing >' do
            subject { eztime1 > eztime2 }
            it { is_expected.to eq newer }
          end
        end
      end

      EASY_TIME_DATA.each do |(time1, time2, result)|
        it_behaves_like 'comparison operators', false, time1, time2, result
        it_behaves_like 'comparison operators', true,  time1, time2, result
      end
    end

    describe '#acts_like_time?' do
      subject { eztime.acts_like_time? }

      let(:eztime) { EasyTime.now }

      it { is_expected.to be true }
    end

    describe '#method_missing' do
      subject { eztime.send(test_name) }
      let(:eztime) { EasyTime.now }

      context 'with a Time instance method that returns a non-time value' do
        let(:test_name) { :asctime }

        it 'should invoke the same method on the Easy_Time time value' do
          expect(eztime.time).to receive(test_name).and_call_original
          subject
        end

        it 'returns non-Time values as-is' do
          expect(subject).to be_a(String)
        end
      end

      context 'with a Time method that returns a time-like value' do
        let(:test_name) { :getutc }

        it 'should invoke the same method on Time' do
          expect(eztime.time).to receive(test_name).and_call_original
          subject
        end

        it 'returns Time-like values as an EasyTime' do
          expect(subject).to be_an(EasyTime)
        end
      end

      context 'with an unknown method' do
        let(:test_name) { :whut? }
        it 'should raise an error' do
          expect { subject }.to raise_error(NoMethodError)
        end
      end
    end

    describe 'respond_to_missing?' do
      subject { EasyTime.respond_to?(test_name) }

      context 'with a known Time method' do
        let(:test_name) { }

      end

      context 'with an unknown method' do

      end
    end

    describe '#easy_time' do
      subject { time.easy_time }

      context 'for Time values' do
        let(:time) { Time.now }
        it { is_expected.to be_an(EasyTime) }
        it "should have an equivalent time value" do
          expect(subject.time).to eq time
        end
      end

      context 'for string values' do
        let(:time) { '2010-09-08T07:06:05-04:00' }
        it { is_expected.to be_an(EasyTime) }
        it { is_expected.to eq Time.parse(time) }
      end

      context 'for DateTime values' do
        let(:time) { DateTime.new(2010,9,8,7,6,5,"+04:00") }
        it { is_expected.to be_an(EasyTime) }
        it { is_expected.to eq Time.iso8601(time.iso8601) }
      end

      context 'for a bad time string' do
        let(:time) { 'no such luck' }
        it "raises an argument error" do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
