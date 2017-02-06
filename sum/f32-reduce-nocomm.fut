-- We use subtraction, because it is not commutative
fun main (xs : [n]f32): f32 =
  reduce (-) 0.0f32 xs
