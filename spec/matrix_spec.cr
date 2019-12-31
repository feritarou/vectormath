require "./spec_helper"
require "../src/matrix"

{% for scalar in %i[Int32 Int64 Float32 Float64 BigFloat] %}

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

macro two(what)
  {(\{{what}}), (\{{what}})}
end

module VM

  {% for m in 1..VM::SUPPORTED_DIMENSIONS %}
  {% for n in 1..VM::SUPPORTED_DIMENSIONS %}

  macro mat
    Mat{{m}}x{{n}}
  end

  macro typed_mat
    Mat{{m}}x{{n}}({{scalar.id}})
  end

  macro arbitrary_mat
    typed_mat.new { rand {{scalar.id}} }
  end

  macro vec
    Vec{{n}}
  end

  macro typed_vec
    Vec{{n}}({{scalar.id}})
  end

  macro arbitrary_vec
    typed_vec.new { rand {{scalar.id}} }
  end

  describe "Mat{{m}}x{{n}}({{scalar.id}})" do
    x = typed_mat.new( {% for i in 1..m %}{% for j in 1..n %} {{i*10 + j}}, {% end %}{% end %})

    context "example matrix for component identification: #{x}" do
      describe "#initialize(&block)" do
        it "creates a matrix with the rows and columns filled in correct order" do
          m = typed_mat.new { |i,j| (i+1)*10 + (j+1) }
          m.should eq x
        end
      end

      describe "#t / #transpose" do
        it "returns the flipped matrix" do
          t = x.transpose
          {{m}}.times do |i|
            {{n}}.times do |j|
              t[j, i].should eq (i+1)*10 + (j+1)
            end
          end
        end

        it "returns the original matrix when applied twice" do
          t  = x.transpose
          tt = t.transpose
          tt.should eq x
        end
      end

      describe "#*(Vec{{n}})" do
        it "performs matrix-vector multiplication" do
          v = Vec{{n}}({{scalar.id}}).new({% for i in 0...n %} {{i}}, {% end %})
          w = x * v
          w.should be_a Vec{{m}}({{scalar.id}})
          w.components.each_with_index do |c, i|
            c.should eq (0...{{n}}).sum { |j| x[i, j] * v[j] }
          end
        end

        it "yields the expected result on a simple test case" do
          a = Mat3x2({{scalar.id}}).new(
             1,  2,
             3,  4,
            -1, -2
          )
          b = Vec2({{scalar.id}}).new(
             5,
            -1
          )
          (a*b).should eq Vec3({{scalar.id}}).new(
             3,
            11,
            -3
          )
        end
      end

      describe "#*(Mat)" do
        it "returns the original matrix when left-multiplied with the identity" do
          i = Mat{{m}}({{scalar.id}}).identity
          (i*x).should eq x
        end

        it "returns the original matrix when right-multiplied with the identity" do
          i = Mat{{n}}({{scalar.id}}).identity
          (x*i).should eq x
        end

        it "yields the expected result on a simple test case" do
          a = Mat3x2({{scalar.id}}).new(
             1,  2,
             3,  4,
            -1, -2
          )
          b = Mat2x4({{scalar.id}}).new(
             5,  4,  3,  2,
            -1, -2, -3, -4
          )
          (a*b).should eq Mat3x4({{scalar.id}}).new(
             3, 0, -3,  -6,
            11, 4, -3, -10,
            -3, 0,  3,   6
          )
        end

        #TODO: Write more tests for general matrix-matrix multiplication
      end
    end

  end

  {% if m == n %}
  describe "Mat{{m}}({{scalar.id}}) (quadratic)" do
    describe ".identity" do
      it "returns the identity matrix" do
        m = typed_mat.identity
      end
    end

    describe "#*(Vec{{n}})" do
      it "returns the original vector when multiplying with the identity" do
        v = arbitrary_vec
        i = Mat{{n}}({{scalar.id}}).identity
        r = i*v
        {% if scalar == :BigFloat %}
        # This case distinction is necessary due to some weird behavior of BigFloat
        # that does not match equality even if the numbers are exactly the same
        r.should be_close_enough_to v
        r.should eq r
        {% else %}
        r.should eq v
        {% end %}
      end
    end

    {% if m == 2 %}
    describe ".rotation" do
      it "rotates the plane CCW by e.g. 90°, so that unit_x is mapped onto unit_y" do
        rot = typed_mat.rotation angle: 90.degrees
        ux, uy = Vec2({{scalar.id}}).unit_x, Vec2({{scalar.id}}).unit_y
        (rot * ux).should be_close_enough_to uy
      end
    end
    {% end %}

    {% if m > 1 %}
    describe ".translation" do
      it "encodes a translation by a {{m-1}}-vector" do
        t = Vec{{m-1}}({{scalar.id}}).new({% for i in 1...m %} {{i}}, {% end %})
        v = Vec{{m-1}}({{scalar.id}}).new { arbitrary_scalar }
        v1 = v.to_vec{{m}} fill_with: 1
        m = typed_mat.translation(t)
        translated = m * v1
        {% if scalar == :BigFloat %}
        # This case distinction is necessary due to some weird behavior of BigFloat
        # that does not match equality even if the numbers are exactly the same
        translated.should be_close_enough_to (v+t).to_vec{{m}}(fill_with: 1)
        {% else %}
        translated.should eq (v+t).to_vec{{m}}(fill_with: 1)
        {% end %}
      rescue OverflowError
        report_overflow
      end
    end
    {% end %}

    {% if m == 4 %}
    #TODO: Think of a test
    describe ".perspective_projection" do
    end
    {% end %}

  end
  {% end %}

  {% end %}
  {% end %}

end

{% end %}
