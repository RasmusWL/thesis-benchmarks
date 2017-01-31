entry main (m : i32, n : i32, input : [mn]f32) : [m]f32 =
  let xss = reshape (m,n) input
  in
  map (\(xs : [n]f32) : f32 ->
        loop (sum = 0.0f32) = for i < n do
            sum + xs[i]
        in sum
    ) xss
