require "big"

struct Number
  # An alias for `range.covers?(self)`.
  def within?(range)
    range.covers? self
  end
end

{% for scalar_type in %i[Int32 Int64 UInt32 Float32 Float64 BigFloat] %}
struct {{scalar_type.id}}
  # One scalar unit (1).
  def self.one
    self.new 1
  end

  # Returns the result of linear interpolation between two values.
  def self.lerp(a, b, weight) : self
    (self.one - self.new weight) * self.new(a) + self.new(weight) * self.new(b)
  end

  # =======================================================================================

  {% unless scalar_type == :Float32 || scalar_type == :Float64 %}
  # Always returns `true` for numbers that are no floats.
  # This method is provided for consistency.
  def finite?
    true
  end

  # Always returns `false` for numbers that are no floats.
  # This method is provided for consistency.
  def infinite?
    false
  end
  {% end %}

  # =======================================================================================

  # Converts `self`, which is expected to be in degrees, to an arc length and returns the result.
  # Example:
  #     180.degrees # => Math::PI
  def degrees
  {% if scalar_type == :Float32 %}
    self * Math::PI / 180f32
  {% else %}
    self * Math::PI / 180
  {% end %}
  end

  # =======================================================================================

  # Converts `self`, which is expected to be an arc length, to degrees and returns the result.
  # Example:
  #     (2*Math::PI).in_degrees # => 360.0
  def in_degrees
  {% if scalar_type == :Float32 %}
    self * 180f32 / Math::PI
  {% else %}
    self * 180 / Math::PI
  {% end %}
  end
end
{% end %}

# =======================================================================================

# The following extensions are provided just for completeness to make the generic code less tedious.

module Math
  def sqrt(value : Int32)
    sqrt(value.to_f32).to_i32
  end

  def sqrt(value : Int64)
    sqrt(value.to_f64).to_i64
  end
end
