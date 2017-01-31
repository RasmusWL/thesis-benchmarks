entry main (m : i32, n : i32, input : [mn]f32) : [m]f32 =
  let xss = reshape (m,n) input
  in  map (\xs -> reduceComm (+) 0.0f32 xs) xss
