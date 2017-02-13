entry main (xss : [m][n]f32): [n][m]f32 =
  transpose(xss)

-- This manual version will generate *both* a transpose, and a map
--
-- entry manual (xss : [m][n]f32): [n][m]f32 =
--   map (\j -> map (\i -> xss[i,j]) (iota m)) (iota n)
