-- No reason to even test this when there are less than 64 active threads.
entry main (xss : [m][n]f32) : [m]f32 =
  if n <= 64
  then replicate (m) 0.0f32
  else
  map (\(xs : [n]f32) : f32 ->
        loop (sum = 0.0f32) = for i < n do
            sum + xs[i]
        in sum
    ) xss
