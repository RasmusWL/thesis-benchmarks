import "shared"

fun main (xss : [m][n]f32): [m]f32 =
  map (\xs -> reduceComm redop 1.0f32 xs) xss
