# This file comprises various basic extensions of the standard library numeric structs.

require "big"

# =======================================================================================
# Extensions of the Number abstract base struct
# =======================================================================================

struct Number
  # An alias for `range.covers?(self)`.
  def within?(range : Range)
    range.covers? self
  end
end

{% for scalar_type in %i[Int32 Int64 UInt32 Float32 Float64 BigFloat] %}
struct {{scalar_type.id}}

  # =======================================================================================
  # Constructors
  # =======================================================================================

  # One scalar unit (1).
  def self.one
    self.new 1
  end

  # ---------------------------------------------------------------------------------------

  # Returns the result of a linear interpolation `(1-t)*a + t*b` between two values *a* and *b*,
  # where *t* is the "weight" of the two factors that variies between 0 (returns *a*) and 1 (returns *b*).
  def self.lerp(a, b, t) : self
    # A complicated way of writing (1-t) * a + t * b
    (self.one - self.new t) * self.new(a) + self.new(t) * self.new(b)
  end

  # =======================================================================================
  # Instance methods
  # =======================================================================================

  {% unless scalar_type == :Float32 || scalar_type == :Float64 %}

  # Always returns `true` for numbers of any type except Float32/Float64.
  # This method is provided for consistency.
  def finite?
    true
  end

  # ---------------------------------------------------------------------------------------

  # Always returns `false` for numbers of any type except Float32/Float64.
  # This method is provided for consistency.
  def infinite?
    false
  end

  {% end %}

  # ---------------------------------------------------------------------------------------

  # Converts `self`, which is expected to be in degrees, to arc length (multiples of PI) and returns the result.
  #     180.degrees # => Math::PI
  def degrees
  {% if scalar_type == :Float32 %}
    (self * Math::PI / 180).to_f32
  {% else %}
    self * Math::PI / 180
  {% end %}
  end

  # ---------------------------------------------------------------------------------------

  # Converts `self`, which is expected to be an arc length (multiples of PI), to degrees and returns the result.
  #     Math::PI.in_degrees # => 180.0
  def in_degrees
  {% if scalar_type == :Float32 %}
    (self * 180 / Math::PI).to_f32
  {% else %}
    self * 180 / Math::PI
  {% end %}
  end
end

{% end %}

# ---------------------------------------------------------------------------------------

# The following extensions are not very useful in most cases; they are provided just for completeness to make generic code less tedious.

# module Math
#   def sqrt(value : Int32)
#     sqrt(value.to_f64).to_i32
#   end
#
#   def sqrt(value : Int64)
#     sqrt(value.to_f64).to_i64
#   end
# end
