require "./tuple"

{% for m in 1..VM::SUPPORTED_DIMENSIONS %}

module VM
  extend self

  # A generic vector struct, built on top of Tuple{{m}}(T) and enriched by some vector-specific operations.
  struct Vec{{m}}(T)
    include Tuple{{m}}(T)

    # =======================================================================================
    # Constructor macro
    # =======================================================================================

    macro [](*args)
      VM::Vec{{m}}(typeof(\{{*args}})).new(\{{*args}})
    end

    # =======================================================================================
    # Vector operations
    # =======================================================================================

    # An alias for `#dot`.
    def *(other : Vec{{m}}(U)) forall U
      dot(other)
    end

    {% if m == 3 %}
    # Returns the cross product (exterior product) of `self` and `other`.
    def cross(other : Vec3) : self
      a1,a2,a3 = @data
      b1,b2,b3 = other.@data
      s1 = a2*b3 - a3*b2
      s2 = a3*b1 - a1*b3
      s3 = a1*b2 - a2*b1
      self.class.new(s1,s2,s3)
    end

    # :ditto:
    def ^(other : Vec3) : self
      cross(other)
    end
    {% end %}

    # Returns the parallel projection of `self` onto one or more *other_vectors*.
    def project_on(*other_vectors)
      other_vectors.sum do |v|
        n = v.normalize
        (self.dot n) * n
      end
    end

    # Parallel projects `self` onto one or more *other_vectors*.
    def project_on!(*other_vectors)
      p = project_on *other_vectors
      @data = p.@data
    end

    # =======================================================================================
    # Dimensional conversions
    # =======================================================================================

    {% for k in 1...m %}
    # Clips the {{m-k}} last components of self and returns the resulting {{k}}-vector.
    def to_vec{{k}}
      Vec{{k}}(T).new({% for i in 0...k %}@data[{{i}}], {% end %})
    end
    {% end %}

    {% for k in m+1..VM::SUPPORTED_DIMENSIONS %}
    # Fills the {{k-m}} last components of self with a value and returns the resulting {{k}}-vector.
    def to_vec{{k}}(fill_with value = T.zero)
      Vec{{k}}(T).new({% for i in 0...m %}@data[{{i}}], {% end %} {% for i in m...k %} T.new(value), {% end %})
    end
    {% end %}
  end

  # Computes the relative angle between two vectors, in arcs.
  def angle_between(a : Vec{{m}}, b : Vec{{m}})
    Math.acos(a.normalize * b.normalize)
  end

  {% for letter, type in {:f => Float32, :d => Float64, :b => BigFloat, :i => Int32, :u => UInt32} %}
  alias Vec{{m}}{{letter.id}} = Vec{{m}}({{type}})

  macro vec{{m}}{{letter.id}}(*args)
    VM::Vec{{m}}({{type}}).new(\{{*args}})
  end

  # A convenience constructor macro to allow GLSL-like expressions of the form `v = vec{{m}}{{letter.id}}(...)`.
  macro vec{{m}}{{letter.id}}(*args)
    VM::Vec{{m}}{{letter.id}}.new(*\{{args}})
  end
  {% end %}

end

{% end %}
