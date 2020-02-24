# This file implements some basic algebraic structure used in all kinds of n-dimensional "tuples" (vectors, quaternions, and matrices).

module VM
  SUPPORTED_DIMENSIONS = 4
end
require "./scalar"

{% for m in 1..VM::SUPPORTED_DIMENSIONS**2 %}

module VM

  # A generic {{m}}-tuple mix-in providing a number of component-wise operations.
  module Tuple{{m}}(T)
    include Indexable(T)
    include Comparable(Tuple{{m}})

    # =======================================================================================
    # Instance variables
    # =======================================================================================

    @data : StaticArray(T, {{m}})

    # =======================================================================================
    # Auto-generated constructors for including types
    # =======================================================================================

    macro included

      # The zero {{m}}-tuple.
      def self.zero : self
        self.new T.zero
      end

      # ---------------------------------------------------------------------------------------

      # The one {{m}}-tuple.
      def self.one : self
        self.new T.one
      end

      # ---------------------------------------------------------------------------------------

      {% for c, n in %i(x y z w) %}
      {% if n < m %}

      # The unit {{m}}-tuple in {{c.id}} direction.
      def self.unit_{{c.id}} : self
        self.new { |i| i == {{n}} ? T.one : T.zero }
      end

      {% end %}
      {% end %}

      # ---------------------------------------------------------------------------------------

      # Returns the result of component-wise linear interpolation between two {{m}}-tuples.
      def self.lerp(a, b, t) : self
        (T.one - T.new t) * a.as_a(self) + T.new(t) * b.as_a(self)
      end

      # ---------------------------------------------------------------------------------------

      # Copy constructor.
      # Since this creates a component-wise copy of *other*, this constructor can be used to cast between {{m}}-tuples of different underlying number types.
      def initialize(other : Tuple{{m}})
        @data = StaticArray(T, {{m}}).new { |i| T.new(other[i]) }
      end

      # ---------------------------------------------------------------------------------------

      # Creates a {{m}}-tuple holding the same *value* in each component.
      def initialize(value = T.zero)
        @data = StaticArray(T, {{m}}).new T.new(value)
      end

      # ---------------------------------------------------------------------------------------

      # Creates a {{m}}-tuple from a *list* of its components.
      def initialize(*list : U) forall U
        @data = StaticArray(T, {{m}}).new { |i| T.new(list[i]) }
      end

      # ---------------------------------------------------------------------------------------

      # Creates a {{m}}-tuple by calling a block for each index, initializing the respective component with the returned value.
      def initialize(&block)
        @data = StaticArray(T, {{m}}).new { |i| T.new(yield i) }
      end

      # ---------------------------------------------------------------------------------------

      # Creates a {{m}}-tuple from a `StaticArray`.
      def initialize(arr : StaticArray(T, {{m}}))
        @data = arr
      end

      # ---------------------------------------------------------------------------------------

      # Creates a {{m}}-tuple from an `Array` which is expected to be of size {{m}}.
      def initialize(arr : Array(T))
        @data = StaticArray(T, {{m}}).new { |i| arr[i] }
      end
    end

    # =======================================================================================
    # Component access
    # =======================================================================================

    # Returns the (i+1)-th component of the {{m}}-tuple.
    def [](i) : T
      @data[i]
    end

    # ---------------------------------------------------------------------------------------

    # Sets the (i+1)-th component of the {{m}}-tuple.
    def []=(i, value)
      @data[i] = value
    end

    # ---------------------------------------------------------------------------------------

    # Returns all components of the {{m}}-tuple as a `StaticArray(T, {{m}})`.
    def components
      @data
    end

    # ---------------------------------------------------------------------------------------

    # Implement GLSL-like "swizzling" components access through accessor methods:
    # E.g., get a Vec2 containing the z and x components of a Vec3 by calling `some_vec.zx`

    {% for c1, i1 in %w(x y z w) %}
      {% if i1 < m %}
        # Returns the {{c1.id}} (={{i1+1}}{% if i1 == 0 %}st{% elsif i1 == 1 %}nd{% elsif i1 == 2 %}rd{% else %}th{% end %}) component of the tuple.
        def {{c1.id}} : T
          @data.unsafe_fetch {{i1}}
        end

        # Sets the {{c1.id}} (={{i1+1}}{% if i1 == 0 %}st{% elsif i1 == 1 %}nd{% elsif i1 == 2 %}rd{% else %}th{% end %}) component of the tuple.
        def {{c1.id}}=(value)
          @data[{{i1}}] = value
        end

        {% for c2, i2 in %w(x y z w) %}
          {% if i2 < m %}
            # Returns a tuple containing the {{c1.id}} (={{i1+1}}{% if i1 == 0 %}st{% elsif i1 == 1 %}nd{% elsif i1 == 2 %}rd{% else %}th{% end %}) and {{c2.id}} (={{i2+1}}{% if i2 == 0 %}st{% elsif i2 == 1 %}nd{% elsif i2 == 2 %}rd{% else %}th{% end %}) components of the tuple ("swizzling").
            def {{(c1+c2).id}} : {T, T}
              {self[{{i1}}], self[{{i2}}]}
            end
            {% for c3, i3 in %w(x y z w) %}
              {% if i3 < m %}
                # Returns a tuple containing the {{c1.id}} (={{i1+1}}{% if i1 == 0 %}st{% elsif i1 == 1 %}nd{% elsif i1 == 2 %}rd{% else %}th{% end %}), {{c2.id}} (={{i2+1}}{% if i2 == 0 %}st{% elsif i2 == 1 %}nd{% elsif i2 == 2 %}rd{% else %}th{% end %}), and {{c3.id}} (={{i3+1}}{% if i3 == 0 %}st{% elsif i3 == 1 %}nd{% elsif i3 == 2 %}rd{% else %}th{% end %}) components of the tuple ("swizzling").
                def {{(c1+c2+c3).id}} : {T, T, T}
                  {self[{{i1}}], self[{{i2}}], self[{{i3}}]}
                end
                {% for c4, i4 in %w(x y z w) %}
                  {% if i4 < m %}
                    # Returns a tuple containing the {{c1.id}} (={{i1+1}}{% if i1 == 0 %}st{% elsif i1 == 1 %}nd{% elsif i1 == 2 %}rd{% else %}th{% end %}), {{c2.id}} (={{i2+1}}{% if i2 == 0 %}st{% elsif i2 == 1 %}nd{% elsif i2 == 2 %}rd{% else %}th{% end %}), {{c3.id}} (={{i3+1}}{% if i3 == 0 %}st{% elsif i3 == 1 %}nd{% elsif i3 == 2 %}rd{% else %}th{% end %}), and {{c4.id}} (={{i4+1}}{% if i4 == 0 %}st{% elsif i4 == 1 %}nd{% elsif i4 == 2 %}rd{% else %}th{% end %}) components of the tuple ("swizzling").
                    def {{(c1+c2+c3+c4).id}} : {T, T, T, T}
                      {self[{{i1}}], self[{{i2}}], self[{{i3}}], self[{{i4}}]}
                    end
                  {% end %}
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    {% end %}

    # =======================================================================================
    # Component-wise operations
    # =======================================================================================

    # Returns the "opposite" {{m}}-tuple by inverting the sign of each component.
    def - : Tuple{{m}}
      self.class.new { |i| -@data.unsafe_fetch(i) }
    end

    # ---------------------------------------------------------------------------------------

    # Returns the "sum" {{m}}-tuple by adding to each component the respective one of *other*.
    def +(other : Tuple{{m}}) : Tuple{{m}}
      self.class.new { |i| @data.unsafe_fetch(i) + other.@data.unsafe_fetch(i) }
    end

    # ---------------------------------------------------------------------------------------

    # Returns the "difference" {{m}}-tuple by subtracting from each component the respective one of *other*.
    def -(other : Tuple{{m}}) : Tuple{{m}}
      self.class.new { |i| @data.unsafe_fetch(i) - other.@data.unsafe_fetch(i) }
    end

    # ---------------------------------------------------------------------------------------

    # Returns the "product" {{m}}-tuple by multiplying each component with the respective one of *other*.
    def *(other : Tuple{{m}}) : Tuple{{m}}
      self.class.new { |i| T.new @data.unsafe_fetch(i) * other.@data.unsafe_fetch(i) }
    end

    # ---------------------------------------------------------------------------------------

    # Returns the "scaled" {{m}}-tuple by multiplying each component with some *factor*.
    def *(factor) : Tuple{{m}}
      self.class.new { |i| T.new @data.unsafe_fetch(i) * factor }
    end

    # ---------------------------------------------------------------------------------------

    # Returns the "quotient" {{m}}-tuple by dividing each component by the respective one of *other*.
    def /(other : Tuple{{m}}) : Tuple{{m}}
      if other.components.any? &.zero?
        raise DivisionByZeroError.new("Cannot divide by #{other} which contains zero components")
      end
      self.class.new { |i| T.new @data.unsafe_fetch(i) / other.@data.unsafe_fetch(i) }
    end

    # ---------------------------------------------------------------------------------------

    # Returns the "scaled" {{m}}-tuple by dividing each component by some *factor*.
    def /(factor) : Tuple{{m}}
      raise DivisionByZeroError.new if factor.zero?
      self.class.new { |i| T.new @data.unsafe_fetch(i) / factor }
    end

    # ---------------------------------------------------------------------------------------

    # Returns the dot product (inner product) of `self` and `other`.
    def dot(other : self)
      @data.zip(other.@data).sum { |t| t[0] * t[1] }
    end

    # =======================================================================================
    # Overloads required by mix-ins
    # =======================================================================================

    def each(&block)
      {{m}}.times \
      { |i| yield @data.unsafe_fetch(i) }
    end

    # ---------------------------------------------------------------------------------------

    def each
      @data.each
    end

    # ---------------------------------------------------------------------------------------

    def unsafe_fetch(index : Int)
      @data.unsafe_fetch(index)
    end

    # ---------------------------------------------------------------------------------------

    def <=>(other : Tuple{{m}})
      case (0...{{m}})
      when .all? { |i| @data[i] == other.@data[i] } then 0
      when .all? { |i| @data[i] < other.@data[i] } then -1
      when .all? { |i| @data[i] > other.@data[i] } then +1
      end
    end

    # =======================================================================================
    # Norm and normalization
    # =======================================================================================

    # Returns the norm of `self`.
    # Depending on whether `T` is a "small" data type (`Int/Float32/64`), this function calculates the norm either directly as the square root of `abs2` or indirectly after scaling down or up all components to reach better numerical stability.
    def norm
      if T == Float32 || T == Float64 || T == Int32 || T == Int64
        e = @data.map { |c| Math.log10(c.abs) }
        χ = 10 ** (e.max.zero? ? e.min : e.max)
        χ = 1 if χ.zero?
        scaled = @data.map { |c| c / χ }
        a = scaled.zip(scaled).sum { |t| t[0] * t[1] }
        root = Math.sqrt a
        result = root * χ
        T.new result
      else
        result = Math.sqrt(abs2)
        T.new result
      end
    end

    # ---------------------------------------------------------------------------------------

    # :ditto
    def length
      norm
    end

    # ---------------------------------------------------------------------------------------

    # :ditto
    def abs
      norm
    end

    # ---------------------------------------------------------------------------------------

    # Returns the dot product (inner product) of `self` with itself.
    def abs2
      self.dot self
    end

    # ---------------------------------------------------------------------------------------

    # Returns the "normalization" of `self`, i.e. `self` divided by its `norm`.
    # Raises a `DivisionByZeroError` if `self` is the null vector.
    def normalize
      l = length
      raise DivisionByZeroError.new if l.zero?
      if l.finite?
        result = self / l
        # puts "normalizing #{self} (length #{length}) -> #{result}"
        result
      else
        (self / 1e6).normalize
      end
    rescue OverflowError
      (self / 1e6).normalize
    end

    # ---------------------------------------------------------------------------------------

    # Replaces `self` with its "normalization", i.e. `self` divided by its `norm`.
    # Raises a `DivisionByZeroError` if `self` is the null vector.
    def normalize!
      raise DivisionByZeroError.new if zero?
      v = normalize
      @data = v.@data
      self
    end

    # ---------------------------------------------------------------------------------------

    # Returns the euclidean distance between `self` and *other*, i.e. `(self - other).length`.
    def distance_to(other)
      (self - other).length
    end

    # =======================================================================================
    # Query and conversion functions
    # =======================================================================================

    # Returns `true` if all components are finite, otherwise `false`.
    def finite?
      components.all? &.finite?
    end

    # ---------------------------------------------------------------------------------------

    # Returns `true` if the norm of the vector equals 1, otherwise `false`.
    def normal?(tolerance = T.zero)
      (norm - T.one).abs <= tolerance
    end

    # ---------------------------------------------------------------------------------------

    # Returns `true` if the vector is null, otherwise `false`.
    def zero?(tolerance = T.zero)
      norm <= tolerance
    end

    # ---------------------------------------------------------------------------------------

    # Returns `true` if all components lie within the specified *bounding_box*, which is expected to be an `Array` of `Range`s, and otherwise `false`.
    def within?(bounding_box)
      @data.each_with_index { |v, i| return false unless v.within? bounding_box[i] }
      true
    end

    # ---------------------------------------------------------------------------------------

    def as_a(other_type : Tuple{{m}}(U).class) forall U
      other_type.new self
    end

    # ---------------------------------------------------------------------------------------

    def to_s(io : IO)
      io << "["
      @data.join ", ", io
      io << "]"
    end

    # ---------------------------------------------------------------------------------------

    def humanize(io : IO, *args)
      io << "["
      (@data.map &.humanize(*args)).join(", ", io)
      io << "]"
    end

    # ---------------------------------------------------------------------------------------

    def humanize(*args)
      String.build do |io|
        humanize(io, *args)
      end
    end

    # ---------------------------------------------------------------------------------------

    # Returns an unsafe pointer to this tuple's data.
    # As all components are contingently stored in a `StaticArray`,
    # the result of this function can used as-is for interaction with OpenGL.
    def to_unsafe
      @data.to_unsafe
    end

  end
end

# =======================================================================================
# Convenience "overloads" of tuple functionality in global/superclass scope
# =======================================================================================

# Returns the euclidean distance between *from* and *to*, i.e. `(from - to).length`.
def distance(from : VM::Tuple{{m}}, to : VM::Tuple{{m}})
  from.distance_to to
end

# ---------------------------------------------------------------------------------------

struct Number

  # Multiplies each component of a *tuple* with `self`, and returns the resulting "scaled" tuple.
  def *(tuple : VM::Tuple{{m}}) : VM::Tuple{{m}}
    tuple * self
  end

end

{% end %}
