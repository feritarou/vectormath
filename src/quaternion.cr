require "./tuple"
require "./vector"
require "./matrix"

module VM

  struct Quaternion(T)
    include Tuple4(T)
    include Comparable(Quaternion)

    # =======================================================================================
    # Constructor macro
    # =======================================================================================

    macro [](axis, angle)
      Quaternion(typeof({{axis}}.x)).new({{axis}}, {{angle}})
    end

    # =======================================================================================
    # Constructors
    # =======================================================================================

    # The identity (or one) quaternion.
    def self.identity : self
      self.new 0, 0, 0, 1
    end

    # Performs a spherical linear extrapolation between two unit quaternions *q1* and *q2*.
    # As the parameter *t* varies within the range `0..1`, the rotation/orientation represented by the returned quaternion gradually changes from *q1* to *q2*.
    def self.slerp(q1 : Quaternion, q2 : Quaternion, t)
      dot = q1.dot q2

      # If the dot product is negative, slerp won't take
      # the shorter path. Fix by reversing one quaternion.
      if dot < 0
        q2 = -q2
        dot = -dot
      end

      if dot > 0.9995
        # If the inputs are too close for comfort, linearly interpolate
        # and normalize the result.
        lerp(q1, q2, t).normalize
      else
        # Since dot is in range [0, 0.9995], acos is safe
        α = Math.acos dot   # α = angle between input vectors
        β = α*t             # β = angle between q1 and result
        sin_β = Math.sin β
        sin_α = Math.sin α

        s1 = Math.cos(β) - dot * sin_β / sin_α  # == sin(α - β) / sin(α)
        s2 = sin_β / sin_α

        (s1 * q1) + (s2 * q2)
      end
    end

    # Constructs a rotation from an *angle* and the *axis* to rotate about.
    # This function expects *axis* to be a unit vector; if it does not have unit length, the resulting quaternion will not be a unit quaternion and thus not represent a rotation.
    def initialize(axis : Vec3, angle = T.zero)
      half_angle = angle / 2
      r = axis * Math.sin(half_angle)
      s = Math.cos(half_angle)
      initialize T.new(r[0]), T.new(r[1]), T.new(r[2]), T.new(s)
    end

    # =======================================================================================
    # Real and imaginary parts
    # =======================================================================================

    # Returns the "imaginary" part of `self`.
    def imag : Vec3(T)
      Vec3(T).new x, y, z
    end

    def real : T
      T.new w
    end

    # =======================================================================================
    # Quaternion-specific operations
    # =======================================================================================

    # Returns the conjugate of `self`.
    # With unit quaternions, the conjugate can be interpreted as the inverse rotation, e.g. `~q * q = identity`.
    def ~
      self.class.new(-x, -y, -z, w)
    end

    # Returns the quaternion product of `self` with *q*.
    # This multiplication can be interpreted as chaining together two rotations.
    def *(q : Quaternion)
      rx = (w * q.x) + (x * q.w) + (y * q.z) - (z * q.y)
      ry = (w * q.y) - (x * q.z) + (y * q.w) + (z * q.x)
      rz = (w * q.z) + (x * q.y) - (y * q.x) + (z * q.w)
      rw = (w * q.w) - (x * q.x) - (y * q.y) - (z * q.z)
      Quaternion(typeof(rx, ry, rz, rw)).new(rx, ry, rz, rw)
    end

    # Efficiently rotates the vector *v* around the origin.
    def apply_to(v : Vec3)
      v + 2 * (imag ^ ((imag ^ v) + real * v))
    end

    # :ditto:
    def *(v : Vec3)
      apply_to v
    end

    # =======================================================================================
    # Comparisons
    # =======================================================================================

    # Returns either `self` or `-self`, one of the two covers in the group S³
    # of unit quaternions which represent the same rotation, depending on which one lies on the same semisphere as the quaternion *to* which it should be compared.
    # This function assumes that `self` (and thus `-self`) is a unit quaternion. It is used internally by the implementation of the comparison operator `#<=>`; you can use it in the same spirit whenever you actually want to compare two rotations/attitudes by means of (any of) their quaternion representations.
    def get_comparable(to other : Quaternion) : self
      # Heuristically determine whether the components "generally" point into opposed directions or not
      score = 0
      4.times do |i|
        if @data[i].sign == other[i].sign
          score += 1
        else
          score -= 1
        end
      end
      score >= 0 ? self : -self
    end

    def <=>(other : Quaternion)
      compare = other.get_comparable to: self

      case (0...4)
      when .all? { |i| @data[i] < compare[i] } then -1
      when .all? { |i| @data[i] > compare[i] } then +1
      when .all? { |i| @data[i] == compare[i] } then 0
      end
    end

    # =======================================================================================
    # Conversion functions
    # =======================================================================================

    def to_axis_and_angle
      θ = 2 * Math.atan2(imag.norm, real)
      ω = θ.zero? ? Vec3(T).zero : imag / Math.sin(θ/2)
      {ω, T.new θ}
    end

    def to_mat3x3
      Mat3(T).new(
        1 - 2*y**2- 2*z**2, 	2*x*y - 2*z*w, 	2*x*z + 2*y*w,
        2*x*y + 2*z*w, 	1 - 2*x**2- 2*z**2, 	2*y*z - 2*x*w,
        2*x*z - 2*y*w, 	2*y*z + 2*x*w, 	1 - 2*x**2- 2*y**2
      )
    end
  end

  alias Rotation = Quaternion(Float32)
  alias Orientation = Quaternion(Float32)

end

struct Number
  def *(q : VM::Quaternion)
    q * self
  end
end
