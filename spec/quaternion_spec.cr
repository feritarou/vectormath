require "./spec_helper"
require "../src/quaternion"

macro arbitrary_angle
  α = RNG.rand * 360
  β = α - 180
  β.degrees
end

{% for scalar in %i[Float32 Float64 BigFloat] %}

macro be_close_enough_to(value)
{% if scalar.includes? "Int" %}
  be_close(\{{value}}, 1)
{% else %}
  be_close(\{{value}}, (\{{value}} / 1_000).abs)
{% end %}
end

macro arbitrary_scalar
  rand {{scalar.id}}
end

module VM

  macro typed_vec
    Vec3({{scalar.id}})
  end

  macro arbitrary_vec
    typed_vec.new { arbitrary_scalar }
  end

  macro arbitrary_unit_vec
    arbitrary_vec.normalize
  end

  macro typed_quat
    Quaternion({{scalar.id}})
  end

  macro arbitrary_unit_quat
    typed_quat.new arbitrary_unit_vec, arbitrary_angle
  end

  describe "Quaternion({{scalar.id}})" do
    describe "#initialize / #to_axis_and_angle" do
      v = arbitrary_unit_vec
      α = arbitrary_angle
      q = typed_quat.new v, α

      it "creates a quaternion from axis and angle" do
        q.should be_a Quaternion({{scalar.id}})
        s = Quaternion[v, α]
        s.should be_close_enough_to q
      end

      it "returns an axis (possibly opposed to the one used for creation) and an angle (possibly different from the one used for creation) from which the original quaternion can be approximately reconstructed" do
        w, β = q.to_axis_and_angle
        score = 0
        3.times { |i| score += v[i].sign == w[i].sign ? 1 : -1 }
        sign = score >= 0 ? 1 : -1
        w.should be_close_enough_to sign*v
        r = typed_quat.new w, β
        r.should be_close_enough_to q.get_comparable(to: r)
        # expect reduced accuracy after the back-and-forth conversions
      end
    end

    describe ".slerp" do
      q, r = two arbitrary_unit_quat

      it "returns the first quaternion if called with t=0" do
        s = typed_quat.slerp(q, r, 0)
        s.should be_close_enough_to q.get_comparable(to: s)
      end

      it "returns the second quaternion if called with t=1" do
        t = typed_quat.slerp(q, r, 1)
        t.should be_close_enough_to r.get_comparable(to: t)
      end

      it "gives a sequence of unit quaternions close to each other", tags: "slow" do
        n = 1_000_000
        Δ = 1/n
        first, last = two arbitrary_unit_quat
        q1 = first
        (1..n).each do |k|
          q2 = typed_quat.slerp(first, last, k*Δ).get_comparable(to: q1)
          q2.should be_close_enough_to q1
          q1 = q2
        end
      end
    end

    describe "#apply_to / #*(Vec3)" do
      it "does not change a vector when the applied quaternion is the identity" do
        i = typed_quat.identity
        v = arbitrary_vec
        (i*v).should eq v
      end

      it "rotates the X/Y/Z axis unit vectors onto one another" do
        ux, uy, uz = typed_vec.unit_x, typed_vec.unit_y, typed_vec.unit_z
        (Rotation[uz, 90.degrees] * ux).should be_close_enough_to uy
        (Rotation[ux, 90.degrees] * uy).should be_close_enough_to uz
        (Rotation[uy, 90.degrees] * uz).should be_close_enough_to ux

        (Rotation[uz, -90.degrees] * uy).should be_close_enough_to ux
        (Rotation[ux, -90.degrees] * uz).should be_close_enough_to uy
        (Rotation[uy, -90.degrees] * ux).should be_close_enough_to uz
      end

      it "rotates a vector so that the original one can be retrieved by applying the conjugate to the result" do
        v = arbitrary_vec
        q = arbitrary_unit_quat
        w = q*v
        if w.finite?
          u = ~q * w
          u.should be_close_enough_to v
        end
      end
    end

    describe "#*(Quaternion)" do
      it "chains together two rotations" do
        q1, q2 = two arbitrary_unit_quat
        r = q2 * q1

        v = arbitrary_vec
        v1 = q1 * v
        v2 = q2 * v1

        vr = r * v

        if v2.finite? && vr.finite?
          vr.should be_close_enough_to v2
        end
      end

      it "is reversable via the conjugate" do
        q1, q2 = two arbitrary_unit_quat
        r = q2 * q1
        (~q2 * r).should be_close_enough_to q1
      end

      it "can be used to compose a 360° rotation around some axis" do
        axis = arbitrary_unit_vec
        q = Rotation[axis, 1.degrees]
        r = Rotation.identity
        360.times { r *= q }

        v = arbitrary_unit_vec
        w = r*v
        w.should be_close_enough_to v
      end
    end

    describe "#to_mat3x3" do
      it "returns a rotation matrix that has equivalent effects on vectors" do
        v = arbitrary_vec
        q = arbitrary_unit_quat
        w1 = q*v
        if w1.finite?
          m = q.to_mat3x3
          w2 = m*v
          if w2.finite?
            w2.should be_close_enough_to w1
          end
        end
      end
    end
  end

end

{% end %}
