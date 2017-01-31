entry main (xss : [m][n]f32) : [m]f32 =
  map (\xs -> reduceComm (+) 0.0f32 xs) xss
