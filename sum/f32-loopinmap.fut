entry main (xss : [m][n]f32) : [m]f32 =
  map (\(xs : [n]f32) : f32 ->
        loop (sum = 0.0f32) = for i < n do
            sum + xs[i]
        in sum
    ) xss
