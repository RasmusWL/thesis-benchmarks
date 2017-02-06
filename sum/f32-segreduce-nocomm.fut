-- We use subtraction, because it is not commutative
entry main (xss : [m][n]f32) : [m]f32 =
 map (\xs -> reduce (-) 0.0f32 xs) xss
