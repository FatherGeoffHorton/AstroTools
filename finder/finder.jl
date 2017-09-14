
using Images

struct star
  maxval
  x::Int32
  y::Int32
end

function center_of_mass(x::Int, y::Int)
  offset::Int32 = floor(EDGE / 2)
  cells = img[y - offset:y + offset, x - offset:x + offset]
  weights::Float32 = 0.0
  xsum::Float32 = 0.0
  ysum::Float32 = 0.0
  for ix = 1:EDGE
    for iy = 1:EDGE
      pixel = cells[ix, iy]
      pixval = min(pixel.r, pixel.g, pixel.b)
      weights += pixval
      xsum += pixval * ix
      ysum += pixval * iy
    end
  end
  centerx = xsum / weights
  centery = ysum / weights
  rx = x + centerx - EDGE
  ry = y + centery - EDGE
  return (rx, ty)
end

filen = "test.png"

print("Loading $filen... ")
img = load(filen)
if img == nothing
  println("Image failed to load.")
  exit(-1)
end

EDGE::Int32 = 25 # size of one cell and of one centroid for isolating stars
          # This is also the size of the unused margin around the photo (so that centroid seeking doesn't wander off the picture)
CUTMAX::Float16 = 0.90 # don't use maxima above this because they're probaby wrong
CUTMIN::Float16 = 0.01 # don't use maxuma below this because they're probably just noise
STARCOUNT::Int32 = 40 # How many stars are we looking for?
EPSILON::Int32 = 2 # How close do two potential stars have to be to count as the same
println("Done!")
sz = size(img)
px::Int32 = sz[1]
py::Int32 = sz[2]
println("Image size: ", px, "x", py, " pixels")
imagetype::Type = typeof(img[1, 1].r)
println("Image kind ", imagetype)
colcells::Int32 = floor((px - 2 * EDGE) / EDGE)
rowcells::Int32 = floor((py - 2 * EDGE) / EDGE)

maxval = zeros(imagetype, rowcells * colcells)
maxx = zeros(UInt32, rowcells * colcells)
maxy = zeros(UInt32, rowcells * colcells)

# find max in each cell
yc::Int32 = EDGE
yptr::Int32 = 1
ptr::Int32 = 1
for y = 1:(EDGE * colcells)
    xc::Int32 = xstep
    xptr::Int32 = 1
    for x = 1:(EDGE * rowcells)
        pixel = img[x, y]
        pixval = min(pixel.r, pixel.g, pixel.b)
        if pixval < CUTMAX & pixval > CUTMIN & pixval > maxval[xptr, yptr]
            maxval[ptr] = pixval
            maxx[ptr] = x
            maxy[ptr] = y
        end
        xc -= 1
        if xc == 0
            xptr += 1
            xc = xstep
        end
        ptr += 1
    end
    yc -= 1
    if yc == 0
        yptr += 1
        yc = ystep
    end
end

# Start processing with the brightest objects

order = sortperm(maxval, rev = true)
stars = Array{star}[]

while size(stars) < STARCOUNT && size(order) > 0
  starval = maxval[order[1]]
  starx = maxx[order[1]]
  stary = maxy[order[1]]
  onestar::star = refine(starx, stary)
  add = true
  if onestar.maxval > 0
    for i = 1:size(stars)
      if abs(starx - stars[i].x) <= EPSILON ||
         abs(stary - stars[i].y) <= EPSILON
         add = false
      end
    end
    if add
      push!(stars, onestar)
    end
  end
  shift!(order)
end

if size(stars) < 5
  println("Warning: Fewer than 5 stars found")
end
