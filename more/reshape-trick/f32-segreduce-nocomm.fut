-- using this function will currently trick the compiler, so it doesn't realize
-- we are actually using a commutative reduction operator
fun add (x : f32) (y : f32): f32 =
  x + y

entry main (m : i32, n : i32, input : [mn]f32) : [m]f32 =
  let xss = reshape (m,n) input
  in map (\xs -> reduce add 0.0f32 xs) xss
