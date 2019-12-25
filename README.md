# vectormath

A pure Crystal linear algebra library providing generic vector, matrix, and quaternion structs.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     vectormath:
       github: mathalaxy/vectormath
   ```

2. Run `shards install`

## Usage

Example:

```crystal
require "vectormath"

v = VM.vec3f(3, 4, 5)
a = VM.mat2x3f(
  1, 0, -1,
  0, 2,  3
)
puts "A=#{a}", "A/2=#{a/2}", "A*v=#{a*v}"
```

The package comprises generic `struct`s for vectors, matrices, and quaternions.
Those structs are all located under the namespace `VM`.

Compared with other packages, `vectormath` classifies vectors and matrices by their underlying scalar type as well as their dimensionality, leading to better type safety. Thus the following are all examples of different types:

- `Vec2(Int32)`
- `Vec2(BigFloat)`
- `Vec3(Complex)`
- `Mat3x2(Float64)`
- `Mat3(Float32)` – which is itself an alias for the quadratic matrix type `Mat3x3(Float32)`.

Objects can be created either through various `new` methods, via bracket macros on the generic types (`Vec3[1, 2, 3]`), or through GLSL-style convenience macros, like in the example at the beginning of this section.

## Development

All classes have been thoroughly tested and are so far working well. As I use them for an OpenGL game engine, the types are made with OpenGL (shader) interoperability in mind.

Currently there is only a small subset of linear algebra implemented. Things that might be very nice to have include:

- Matrix inversion
- Linear equation systems
- Other standard LA algorithms

## Contributing

1. Fork it (<https://github.com/mathalaxy/vectormath/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [mathalaxy](https://github.com/mathalaxy) - creator and maintainer
