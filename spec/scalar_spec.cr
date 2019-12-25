require "./spec_helper"
require "../src/scalar"

{% for scalar in %i[Int32 Int64 Float32 Float64 BigFloat] %}

macro be_close_enough_to(value)
{% if scalar == :Int32 || scalar == :Int64 %}
  be_close(\{{value}}, 0.5)
{% else %}
  (\{{value}}).finite? ? be_close(\{{value}}, \{{value}} / 1_000) : be_a({{scalar.id}})
{% end %}
end

describe "{{scalar.id}}" do
  describe ".one" do
    it "returns a unit value (1) of type {{scalar.id}}" do
      unit = {{scalar.id}}.one
      unit.should be_a {{scalar.id}}
      unit.should eq 1
    end
  end

  describe "#within?" do
    λ = rand {{scalar.id}}
    Δ = λ.abs / 10
    minus  = λ - Δ
    minus2 = λ - 2 * Δ
    plus   = λ + Δ
    plus2  = λ + 2 * Δ

    it "returns true if the number is inside a specified range" do
      λ.within?(minus..plus).should be_true
    end

    it "returns false if the number is not inside a specified range" do
      λ.within?(minus2..minus).should be_false
      λ.within?(plus..plus2).should be_false
    end
  end

  describe "#degrees" do
    it "converts 180 into π" do
      {{scalar.id}}.new(180).degrees.should be_close_enough_to Math::PI
    end

    {% if scalar == :BigFloat %}
    it "is neutralized by #in_degrees when the original value is within [-180, 180)" do
      range = -180.0...180.0
      f = Random.rand range
      λ = BigFloat.new f, 30
    {% elsif scalar == :UInt32 %}
    it "is neutralized by #in_degrees when the original value is within [0, 360)" do
      range = 0u32...360u32
      λ = Random.rand range
    {% else %}
    it "is neutralized by #in_degrees when the original value is within [-180, 180)" do
      range = ( {{scalar.id}}.new -180 )...( {{scalar.id}}.new 180 )
      λ = Random.rand range
    {% end %}

      λ.degrees.in_degrees.should be_close_enough_to λ
    end
  end

  describe "#in_degrees" do
  {% if scalar.id.includes? "Float" %}
    it "converts 2π into 360" do
      {{scalar.id}}.new(2*Math::PI).in_degrees.should be_close_enough_to 360
    end

    it "is neutralized by #degrees" do
      λ = rand {{scalar.id}}
      if (a = λ.in_degrees).finite?
        if (b = a.degrees).finite?
          b.should be_close_enough_to λ
        end
      end
    end
  {% end %}
  end
end

{% end %}
