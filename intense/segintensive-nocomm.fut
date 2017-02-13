import "shared"

fun main (xss : [m][n]f32): [m]f32 =
  map (\xs -> reduce redop 1.0f32 xs) xss
