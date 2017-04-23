
using Images, ImageCore
filen = "test.tif"
topclip = 0.01 # allow this proportion of pixels to be clipped into the top bin
bottomclip = 0.01 # allow this proportion of pixels to be clipped into the bottom bin

print("Loading $filen... ")
img = load(filen)
if img == nothing
  println("Image failed to load.")
  exit(-1)
end
println("Done!")
println("Loading processing vectors and histograms...")
sz = size(img)
px = sz[1]
py = sz[2]
pixcount = px * py
println("\Image size: ", px, "x", py, " pixels")
img = reinterpret(UInt16, img)
imgr = reshape(img[1, :, :], pixcount)
imgg = reshape(img[2, :, :], pixcount)
imgb = reshape(img[3, :, :], pixcount)
imgmax = zeros(imgr)
pixmax = zeros(UInt32, 65536)
for i = 1:pixcount
  peak = imgr[i]
  peak = imgg[i] > peak ? imgg[i] : peak
  peak = imgb[i] > peak ? imgb[i] : peak
  imgmax[i] = peak
  pixmax[peak + 1] += 1
end
println("Image and histograms loaded")

mapto = zeros(UInt32, 1:65536)
topcount = floor(pixcount * topclip)
sofar = 0
ptr = 65536
while sofar < topcount
  sofar += pixmax[ptr]
  mapto[ptr] = 65536
  ptr -= 1
end

topptr = ptr
println("Top clip level = ", topptr)

bottomcount = floor(pixcount * bottomclip)
sofar = 0
ptr = 1
while sofar < bottomcount
  sofar += pixmax[ptr]
  mapto[ptr] = 0
  ptr += 1
end

bottomptr = ptr
println("Bottom clip level = ", bottomptr)

# Linear moving
for i = bottomptr:topptr
  mapto[i] = floor(65536 * (i - bottomptr) / (topptr - bottomptr))
end

ten = floor(pixcount / 10)
ctr = ten
for i = 1:pixcount
  factor = mapto[imgmax[i] + 1] / (imgmax[i] + 1)
  rf = imgr[i] < bottomptr ? imgr[i] : bottomptr
  gf = imgg[i] < bottomptr ? imgg[i] : bottomptr
  bf = imgb[i] < bottomptr ? imgb[i] : bottomptr
  ctr -= 1
  if ctr == 0
    println(i, " of ", pixcount)
    ctr = ten
  end
  imgr[i] = floor(UInt16, factor * (imgr[i] - rf) + rf)
  imgg[i] = floor(UInt16, factor * (imgg[i] - gf) + gf)
  imgb[i] = floor(UInt16, factor * (imgb[i] - bf) + bf)
end

final = zeros(UInt16, 3, px, py)
final[1, :, :] = imgr
final[2, :, :] = imgg
final[3, :, :] = imgb

final = colorview(RGB{N0f16}, final)
#final = reinterpret()
oname = "test.png"
print("Saving $oname... ")
save(oname, final)
println("Done!")
