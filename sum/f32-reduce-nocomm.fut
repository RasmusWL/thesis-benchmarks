-- using this function will currently trick the compiler, so it doesn't realize
-- we are actually using a commutative reduction operator
fun add (x : f32) (y : f32): f32 =
  x + y

fun main (xs : [n]f32): f32 =
  reduce add 0.0f32 xs
