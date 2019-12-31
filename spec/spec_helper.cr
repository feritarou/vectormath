require "spec"
require "random"
require "colorize"

RNG = Random.new
BigFloat.default_precision = 400

module Spec
  struct CloseExpectation
    def match(actual_value)
      if actual_value.responds_to?(:finite?)
        if actual_value.finite?
          (actual_value - @expected_value).abs <= @delta.abs
        else
          false
        end
      else
        (actual_value - @expected_value).abs <= @delta.abs
      end
    end
  end
end

macro rand(number_type)
  {% if number_type.symbolize == :Int32 %}
    RNG.rand -100..100
  {% elsif number_type.symbolize == :Int64 %}
    RNG.rand -1_000i64..1_000i64
  {% elsif number_type.symbolize == :Float32 || number_type.symbolize == :Float64 %}
    # With floating point types, we have to avoid using the whole ::MIN..::MAX
    # range, for somehow it causes value to become Infinity
    {{number_type.id}}.new (RNG.rand * {{number_type.id}}::MAX / 1_000_000) * (RNG.next_bool ? 1 : -1)
  {% elsif number_type.symbolize == :BigFloat %}
    string = String.build do |s|
      s << "-" if RNG.next_bool
      int, dec = two RNG.rand 0..40
      int.times { s << RNG.rand 0..9 }
      s << "." unless int.zero?
      s << "0" if dec.zero?
      dec.times { s << RNG.rand 0..9 }
    end
  	BigFloat.new string
  {% end %}
end

macro two(of the_same)
  {({{the_same}}), ({{the_same}})}
end

def report_overflow
  print "ø".colorize :orange
end
