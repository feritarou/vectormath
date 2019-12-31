require "./tuple"
require "./vector"

module VM

  {% for m in 1..VM::SUPPORTED_DIMENSIONS %}
  {% for n in 1..VM::SUPPORTED_DIMENSIONS %}

  # A generic matrix struct, built on top of Tuple{{m*n}}(T) and enriched by some vector-specific operations.
  struct Mat{{m}}x{{n}}(T)
    include Tuple{{m*n}}(T)

    # =======================================================================================
    # Constructor macro
    # =======================================================================================

    macro [](*args)
      VM::Mat{{m}}x{{n}}(typeof(\{{*args}})).new(\{{*args}})
    end

    # =======================================================================================
    # Constructors
    # =======================================================================================

    # Creates a matrix by yielding {col, row} tuples to a block.
    def initialize(&block)
      @data = StaticArray(T, {{m*n}}).new { |i| T.new(yield i.divmod({{n}})) }
    end

    {% if m == n %} # Quadratic matrices

    # The identity matrix.
    def self.identity
      new { |i, j| i == j ? T.one : T.zero }
    end

    {% if m == 2 %}
    # Creates a matrix that will rotate the 2D-plane by some *angle*.
    def self.rotation(angle θ)
      self.new( Math.cos(θ), -Math.sin(θ), \
                Math.sin(θ),  Math.cos(θ)  )
    end
    {% end %}

    {% if m > 1 %}
    # Creates a translation matrix from a {{m-1}}-vector.
    # Multiplying the resulting matrix with any {{m}}-vector *w* will give the same result as if *v* had been added to the first {{m-1}} components of *w*.
    def self.translation(v : Vec{{m-1}}(T)) : self
      t = identity
      {{m-1}}.times { |i| t[i, {{m-1}}] = v[i] }
      t
    end

    # :ditto:
    def self.translation(*components : T) : self
      translation Vec{{m-1}}(T).new(*components)
    end
    {% end %}

    {% for k in 1...m %}
    # Creates a quadratic matrix from another one of dimension {{k}}.
    # The surplus components will be filled with the respective entries of the {{m}}-dimensional `identity` matrix.
    def initialize(smaller : Mat{{k}}x{{k}}(T))
      initialize do |i, j|
        if i < {{k}} && j < {{k}}
          smaller[i, j]
        else
          i==j ? T.one : T.zero
        end
      end
    end
    {% end %}

    {% if m == 4 %}
    # Returns a 4x4 matrix that, when multiplied against 4-vectors, causes a "perspective projection" distortion.
    # Parameters can be used to specify the field of view (*fov*, in arcs), *aspect*, *near* and *far* clipping plane distances.
    # This works similar to OpenGL's "frustum" functions.
    def self.perspective_projection(fov : T, aspect : T, near : T, far : T) : self
      return identity if fov <= 0 || aspect == 0

      frustum_depth = far - near
      one_over_depth = T.one / frustum_depth
      ρ = T.one / Math.tan(0.5 * fov)

      self.new do |i, j|
        case {i,j}
        when {0,0} then -ρ / aspect
        when {1,1} then ρ
        when {2,2} then far * one_over_depth
        when {3,2} then (-far * near) * one_over_depth
        when {2,3} then T.one
        else T.zero
        end
      end
      result
    end
    {% end %}

    {% end %}

    # =======================================================================================
    # Component access
    # =======================================================================================

    # Returns the component at the *i*-th row and *j*-th column.
    def [](i, j) : T
      @data[{{n}}*i + j]
    end

    # Sets the component at the *i*-th row and *j*-th column to *value*.
    def []=(i, j, value : T)
      @data[{{n}}*i + j] = value
    end

    # Returns the *i*-th row as a {{n}}-vector.
    def row(i) : Vec{{n}}(T)
      Vec{{n}}(T).new { |j| self.[](i, j) }
    end

    # Returns the *j*-th column as a {{m}}-vector.
    def column(j) : Vec{{m}}(T)
      Vec{{m}}(T).new { |i| self.[](i, j) }
    end

    # Returns a `StaticArray` of {{n}}-vectors containing all rows in the matrix.
    def rows
      StaticArray(Vec{{n}}(T), {{m}}).new \
      { |i| row(i) }
    end

    # Returns a `StaticArray` of {{m}}-vectors containing all columns in the matrix.
    def columns
      StaticArray(Vec{{m}}(T), {{n}}).new \
      { |j| column(j) }
    end

    # =======================================================================================
    # Component-wise function overrides
    # =======================================================================================

    def *(factor)
      self.class.new { |i,j| T.new self.[i,j] * factor }
    end

    def /(factor)
      self.class.new { |i,j| T.new self.[i,j] / factor }
    end

    # =======================================================================================
    # Matrix-global operations
    # =======================================================================================

    # Transposes the matrix by swapping its rows and columns.
    def t
      Mat{{n}}x{{m}}(T).new { |i, j| self.[](j, i) }
    end

    # :ditto:
    def transpose
      t
    end

    # =======================================================================================
    # Matrix multiplication operations
    # =======================================================================================

    # Matrix-matrix multiplication
    {% for o in 1..VM::SUPPORTED_DIMENSIONS %}
    def *(other : Mat{{n}}x{{o}})
      Mat{{m}}x{{o}}(T).new do |i, j|
        sum = T.zero
        {{n}}.times do |k|
          sum += @data[{{n}}*i + k] * other.@data[{{o}}*k + j]
        end
        sum
      end
    end
    {% end %}

    # Matrix-vector multiplication
    def *(vector : Vec{{n}})
      Vec{{m}}(T).new do |i|
        sum = T.zero
        {{n}}.times do |k|
          sum += @data[{{n}}*i + k] * vector[k]
        end
        sum
      end
    end

    # =======================================================================================
    # Conversions
    # =======================================================================================

    def to_s(io : IO)
      rows.each do |row|
        io << "\n[\t"
        row.join(", ", io)
        io << "\t]"
      end
      io << "\n"
    end

    def to_a
      @data
    end

    {% if m == 1 %}
    def to_v
      Vec{{n}}(T).new @data
    end
    {% elsif n == 1 %}
    def to_v
      Vec{{m}}(T).new @data
    end
    {% end %}

  end

  {% for letter, type in {:f => Float32, :d => Float64, :b => BigFloat, :i => Int32, :u => UInt32} %}
  alias Mat{{m}}x{{n}}{{letter.id}} = Mat{{m}}x{{n}}({{type}})

  macro mat{{m}}x{{n}}{{letter.id}}(*args)
    VM::Mat{{m}}x{{n}}({{type}}).new(\{{*args}})
  end
  {% end %}

  {% end %} # columns (n)

  alias Mat{{m}} = Mat{{m}}x{{m}}
  {% for letter, type in {:f => Float32, :d => Float64, :b => BigFloat, :i => Int32, :u => UInt32} %}
  alias Mat{{m}}{{letter.id}} = Mat{{m}}({{type}})

  macro mat{{m}}{{letter.id}}(*args)
    VM::Mat{{m}}({{type}}).new(\{{*args}})
  end
  {% end %}

  {% end %} # rows (m)

end
