require "./spec_helper"
require "../src/tuple"

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

{% for m in 1..VM::SUPPORTED_DIMENSIONS**2 %}

  struct TupleTester{{m}}(T)
    include Tuple{{m}}(T)
  end

  macro tuple
    TupleTester{{m}}
  end

  macro typed_tuple
    TupleTester{{m}}({{scalar.id}})
  end

  macro arbitrary_tuple
    typed_tuple.new { arbitrary_scalar }
  end

  describe "Tuple{{m}}({{scalar.id}})" do

    # =======================================================================================
    # Constructor tests
    # =======================================================================================

    describe ".zero" do
      it "returns the zero tuple" do
        t = typed_tuple.zero
        t.components.all? &.should eq {{scalar.id}}.zero
      end
    end

    describe ".one" do
      it "returns the one tuple" do
        t = typed_tuple.one
        t.components.all? &.should eq {{scalar.id}}.one
      end
    end

    {% for c, n in %i(x y z w) %} {% if n < m %}
    describe ".unit_{{c.id}}" do
      it "returns the unit {{c.id}} tuple" do
        t = typed_tuple.unit_{{c.id}}
        t.components.each_with_index do |component, index|
          component.should eq ( index == {{n}} ? {{scalar.id}}.one : {{scalar.id}}.zero )
        end
      end
    end

    {% end %} {% end %}

    {% if scalar.includes? "Float" %}
    describe ".lerp" do
      a, b = two arbitrary_tuple

      context "for a=#{a}, b=#{b}" do
        it "returns the first argument if weight is 0" do
          l = typed_tuple.lerp a, b, 0
          l.should be_close_enough_to a
        end

        it "returns the second argument if weight is 1" do
          l = typed_tuple.lerp a, b, 1
          l.should be_close_enough_to b
        end

        it "returns (first + second) / 2 if weight is 0.5" do
          l = typed_tuple.lerp a, b, 0.5
          l.should be_close_enough_to (a/2 + b/2)
        end
      end
    end
    {% end %}

    describe "#initialize(other : Tuple{{m}})" do
      it "creates a component-wise copy of other" do
        original = arbitrary_tuple
        copy = typed_tuple.new original
        copy.should be_a Tuple{{m}}({{scalar.id}})
        copy.should eq original
      end
    end

    describe "#initialize(value)" do
      it "creates a {{m}}-tuple with each component set to value" do
        value = arbitrary_scalar
        t = typed_tuple.new value
        t.should be_a Tuple{{m}}({{scalar.id}})
        t.components.all? &.should eq value
      end
    end

    describe "#initialize(*list)" do
      it "creates a {{m}}-tuple from a list of its components" do
        list = { {% for i in 0...m %} arbitrary_scalar, {% end %} }
        t = typed_tuple.new *list
        t.should be_a Tuple{{m}}({{scalar.id}})
        t.components.each_with_index { |c, i| c.should eq list[i] }
      end
    end

    describe "#initialize(&block)" do
      it "creates a {{m}}-tuple by yielding each of its components to a block" do
        list = { {% for i in 0...m %} arbitrary_scalar, {% end %} }
        t = typed_tuple.new do |comp|
          list[comp]
        end
        t.should be_a Tuple{{m}}({{scalar.id}})
        t.components.each_with_index { |c, i| c.should eq list[i] }
      end
    end

    describe "#initialize(static_array)" do
      it "creates a {{m}}-tuple from a static {{m}}-array" do
        arr = StaticArray({{scalar.id}}, {{m}}).new {arbitrary_scalar}
        t = typed_tuple.new arr
        t.should be_a Tuple{{m}}({{scalar.id}})
        t.components.each_with_index { |c, i| c.should eq arr[i] }
      end
    end

    describe "#initialize(array)" do
      it "creates a {{m}}-tuple from an array of size {{m}}" do
        arr = Array.new({{m}}) {arbitrary_scalar}
        t = typed_tuple.new arr
        t.should be_a Tuple{{m}}({{scalar.id}})
        t.components.each_with_index { |c, i| c.should eq arr[i] }
      end

      {% if m > 1 %}
      it "raises an error if the array's size is < {{m}}" do
        arr = Array.new({{m-1}}) {arbitrary_scalar}
        expect_raises(IndexError) do
          typed_tuple.new arr
        end
      end
      {% end %}
    end

    # =======================================================================================
    # Component-wise operations tests
    # =======================================================================================

    describe "#-" do
      it "inverts each component of the {{m}}-tuple" do
        plus = arbitrary_tuple
        minus = -plus
        minus.should be_a Tuple{{m}}({{scalar.id}})
        minus.components.each_with_index { |c, i| c.should eq -plus[i] }
      rescue OverflowError
        report_overflow
      end
    end

    describe "#+(other)" do
      it "computes and returns the component-wise sum of two tuples" do
        a, b = two arbitrary_tuple
        sum = a + b
        sum.should be_a Tuple{{m}}({{scalar.id}})
        sum.components.each_with_index do |c, i|
          if c.finite?
            c.should be_close_enough_to a[i] + b[i]
          else
            c.should eq a[i] + b[i]
          end
        end
      rescue OverflowError
        report_overflow
      end
    end

    describe "#-(other)" do
      it "computes and returns the component-wise difference of two tuples" do
        a, b = two arbitrary_tuple
        difference = a - b
        difference.should be_a Tuple{{m}}({{scalar.id}})
        difference.components.each_with_index do |c, i|
          if c.finite?
            c.should be_close_enough_to a[i] - b[i]
          else
            c.should eq a[i] - b[i]
          end
        end
      rescue OverflowError
        report_overflow
      end
    end

    describe "#*(other)" do
      it "computes and returns the component-wise product of two tuples" do
        a, b = two arbitrary_tuple
        product = a * b
        product.should be_a Tuple{{m}}({{scalar.id}})
        product.components.each_with_index do |c, i|
          if c.finite?
            c.should be_close_enough_to a[i] * b[i]
          else
            c.should eq a[i] * b[i]
          end
        end
      rescue OverflowError
        report_overflow
      end
    end

    describe "#*(factor)" do
      it "computes and returns the scalar product of self and a factor" do
        factor = arbitrary_scalar
        a = arbitrary_tuple
        product = a * factor
        product.should be_a Tuple{{m}}({{scalar.id}})
        product.components.each_with_index do |c, i|
          if c.finite?
            c.should be_close_enough_to a[i] * factor
          else
            c.should eq a[i] * factor
          end
        end
        product2 = factor * a
        product2.should eq product
      rescue OverflowError
        report_overflow
      end
    end

    describe "#/(other)" do
      it "computes and returns the component-wise quotient of two tuples" do
        a, b = two arbitrary_tuple
        # Avoid division by zero attempts
        {{m}}.times { |i| b[i] += {{scalar.id}}.one if b[i].zero? }
        quotient = a / b
        quotient.should be_a Tuple{{m}}({{scalar.id}})
        quotient.components.each_with_index do |c, i|
          if c.finite?
            c.should be_close_enough_to a[i] / b[i]
          else
            c.should eq a[i] / b[i]
          end
        end
      rescue OverflowError
        report_overflow
      end
    end

    describe "#/(factor)" do
      it "computes and returns the scalar quotient of self and a factor" do
        factor = arbitrary_scalar
        # Avoid division by zero attempts
        factor += {{scalar.id}}.one if factor.zero?
        a = arbitrary_tuple
        quotient = a / factor
        quotient.should be_a Tuple{{m}}({{scalar.id}})
        quotient.components.each_with_index do |c, i|
          if c.finite?
            c.should be_close_enough_to a[i] / factor
          else
            c.should eq a[i] / factor
          end
        end
      rescue OverflowError
        report_overflow
      end
    end

    describe "#dot" do
      it "computes and returns the dot product of two {{m}}-tuples" do
        a, b = two arbitrary_tuple
        dot = a.dot b
        dot.should be_a {{scalar.id}}
        sum = 0
        a.components.zip(b.components) { |c, d| sum += c*d }
        if sum.finite?
          dot.should be_close_enough_to sum
        elsif sum.infinite?
          dot.should eq sum
        end
      rescue OverflowError
        report_overflow
      end
    end

    # =======================================================================================
    # Norm and normalization operations tests
    # =======================================================================================

    describe "#norm" do
      it "returns the norm (length) of the {{m}}-tuple" do
        λ = arbitrary_scalar.abs
        a = typed_tuple.unit_x
        a.norm.should eq 1
        (λ*a).norm.should be_close_enough_to λ
      rescue OverflowError
        report_overflow
      end
    end

    {% unless scalar == :Int32 || scalar == :Int64 %}
    describe "#normalize" do
      a = arbitrary_tuple

      it "returns the normalized (unit) tuple pointing in the same direction as self or raises a DivisionByZeroError if self is the zero vector" do
        if a.zero?
          expect_raises(DivisionByZeroError) do
            a.normalize
          end
        else
          normal = a.normalize
          normal.length.should be_close_enough_to 1
        end
      rescue OverflowError
        report_overflow
      end
    end

    describe "#normalize!" do
      a = arbitrary_tuple

      it "normalizes the tuple in-place or raises a DivisionByZeroError if self is the zero vector" do
        if a.zero?
          expect_raises(DivisionByZeroError) do
            a.normalize!
          end
        else
          a.normalize!
          a.length.should be_close_enough_to 1
        end
      rescue OverflowError
        report_overflow
      end
    end
    {% end %}

    describe "#distance_to" do
      it "computes the euclidean distance between two tuples" do
        Δ = arbitrary_scalar.abs
        a = arbitrary_tuple
        ξ = Random.rand 0...{{m}}
        b = typed_tuple.new { |c| c == ξ ? a[c] + Δ : a[c] }
        dist = a.distance_to b
        if dist.finite?
          dist.should be_close_enough_to Δ
        end
      rescue OverflowError
        report_overflow
      end
    end

    # =======================================================================================
    # Query and conversion functions tests
    # =======================================================================================

    describe "#finite?" do
      it "returns true if all components are finite" do
        a = arbitrary_tuple
        a.finite?.should be_true
      end
    end

    describe "#zero?" do
      it "returns true for the null tuple" do
        o = typed_tuple.zero
        o.zero?.should be_true
      end
    end

    {% unless scalar == :Int32 || scalar == :Int64 %}
    describe "#normal?" do
      it "returns true for normal tuples" do
        a = arbitrary_tuple
        if a.zero?
          expect_raises(DivisionByZeroError) do
            a.normalize!
          end
        else
          a.normalize!
          a.normal?(tolerance: 0.01) .should be_true
        end
      rescue OverflowError
        report_overflow
      end
    end
    {% end %}

  end

{% end %}

end

{% end %}
