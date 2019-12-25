require "spec"
require "random"

module VM
  SUPPORTED_DIMENSIONS = 4
end

RNG = Random.new

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
  {% if number_type.symbolize == :Int32 || number_type.symbolize == :Int64 %}
    RNG.rand {{number_type.id}}::MIN..{{number_type.id}}::MAX
  {% elsif number_type.symbolize == :Float32 || number_type.symbolize == :Float64 %}
    # With floating point types, we have to avoid using the whole ::MIN..::MAX
    # range, for somehow it causes value to become Infinity
    {{number_type.id}}.new (RNG.rand {{number_type.id}}::MAX) * (RNG.next_bool ? 1 : -1)
  {% elsif number_type.symbolize == :BigFloat %}
		σ = BigFloat.new (RNG.next_bool ? 1 : -1)
		a = BigFloat.new RNG.rand(Int64::MIN..Int64::MAX).to_f, RNG.rand(0...15)
		b = BigFloat.new RNG.rand(Int64::MIN..Int64::MAX).to_f, RNG.rand(15...30)
		c = BigFloat.new RNG.rand(Int64::MIN..Int64::MAX).to_f, RNG.rand(30...45)
		BigFloat.new σ * (a+b+c)
  {% end %}
end

macro two(of the_same)
  {({{the_same}}), ({{the_same}})}
end
