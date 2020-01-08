# Vectormath <-> SFML conversion interface.

# Don't include this file if CrSFML is unavailable
{% skip_file if system("find . -path ./lib/crsfml").empty? %}

require "crsfml"

{% for m in 0...VM::SUPPORTED_DIMENSIONS %}

module VM
  struct Vec{{m}}(T)
    {% if m == 2 || m == 3 %}
    # Creates a `Vec{{m}}` from a CrSFML `SF::Vector{{m}}`.
    def self.initialize(sfml_vector : SF::Vector{{m}})
      initialize sfml_vector.x, sfml_vector.y{% if m == 3 %}, sfml_vector.z{% end %})
    end

    # Converts `self` to the respective `SF::Vector{{m}}` and returns the result.
    def to_sfml
      SF::Vector{{m}}(T).new(@data[0], @data[1]{% if m == 3 %}, @data[2]{% end %})
    end
    {% end %}
  end
end

{% end %}
