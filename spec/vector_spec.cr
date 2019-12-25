require "./spec_helper"
require "bit_array"
require "../src/vector"

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

module VM

  {% for m in 1..VM::SUPPORTED_DIMENSIONS %}

  macro vec
    Vec{{m}}
  end

  macro typed_vec
    Vec{{m}}({{scalar.id}})
  end

  macro arbitrary_vec
    typed_vec.new { arbitrary_scalar }
  end

  describe "Vec{{m}}({{scalar.id}})" do

    describe "#new" do
      it "creates a null vector" do
        v = typed_vec.new
        v.should eq typed_vec.zero
      end
    end

    describe "#*(other : Vec)" do
      it "computes the dot product" do
        a, b = two arbitrary_vec
        c = a * b
        d = a.dot b
        c.should eq d if c.finite?
      rescue OverflowError
      end

      it "returns the correct dot product of (3, 4, 5) and (1, 2, 3): 26" do
        v = Vec3({{scalar.id}}).new(3, 4, 5)
        w = Vec3({{scalar.id}}).new(1, 2, 3)
        (v*w).should eq 26
      end
    end

    {% if m == 3 %}
    describe "#cross / #^" do
      it "computes the cross product" do
        a, b = two arbitrary_vec
        c = a ^ b
        d = a.cross b
        if c.finite?
          c.should eq d
          ac = a * c
          bc = b * c
          ac.should be_close_enough_to 0
          bc.should be_close_enough_to 0
        end
      rescue OverflowError
      end
    end
    {% end %}

    describe "#project_on!" do
      it "computes the parallel projection of self onto one or more axis-aligned unit vectors" do
        a = arbitrary_vec
        ba = BitArray.new {{m}}
        guaranteed = RNG.rand 0...{{m}}
        ba[guaranteed] = true
        {{m}}.times { |i| ba[i] = RNG.next_bool unless i == guaranteed }
        {{m}}.times do |i|
          if ba[i]
            unit = typed_vec.new { |c| c == i ? 1 : 0 }
            a.project_on! unit
          end
        end
        a.components.each_with_index { |c, i| c.should eq 0 unless ba[i] }
      end

      it "projects self onto one or more vectors" do
        a, b = two arbitrary_vec
        p = a.project_on b
        a.project_on! b
        a.should eq p
      end
    end

    describe "dimensional conversions" do
      {% for k in 1...m %}
      describe "#to_vec{{k}}" do
        it "shrinks self to a {{k}}-vector, keeping the first {{k}} components and throwing away the others" do
          a = arbitrary_vec
          s = a.to_vec{{k}}
          s.should be_a Vec{{k}}({{scalar.id}})
          {{k}}.times { |i| s[i].should eq a[i] }
        end
      end
      {% end %}

      {% for k in m+1..VM::SUPPORTED_DIMENSIONS %}
      describe "#to_vec{{k}}" do
        it "grows self to a {{k}}-vector, keeping the first {{k}} components and filling the others with a default value" do
          η = arbitrary_scalar
          a = arbitrary_vec
          s = a.to_vec{{k}} η
          s.should be_a Vec{{k}}({{scalar.id}})
          {{k}}.times do |i|
            if i < {{m}}
              s[i].should eq a[i]
            else
              s[i].should eq η
            end
          end
        end
      end
      {% end %}
    end
  end

  describe "angle_between(a : Vec{{m}}, b : Vec{{m}})" do
    {% if m > 1 %}
    it "returns 90° when called on different canonical base vectors" do
      c1 = RNG.rand 0...{{m}}
      c2 = if c1.zero?
        RNG.rand 1...{{m}}
      else
        try = RNG.rand 1...{{m}}
        try == c1 ? 0 : try
      end

      e1 = typed_vec.new { |c| c == c1 ? 1 : 0 }
      e2 = typed_vec.new { |c| c == c2 ? 1 : 0 }

      θ = angle_between(e1, e2)
      θ.should be_close_enough_to 90.degrees
    end
    {% end %}
  end

{% end %}

end

{% end %}
