
using Images
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
println("Image loading time: ", toq())
println("Loading processing vectors and histograms...")
tic()
sz = size(img)
px = sz[1]
py = sz[2]
pixcount = px * py
println("\Image size: ", px, "x", py, " pixels")
img = reinterpret(UInt16, img)
imgr = reshape(img[1, :, :], npix)
imgg = reshape(img[2, :, :], npix)
imgb = reshape(img[3, :, :], npix)
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
print("Top clip level = ", topptr)

bottomcount = floor(pixcount * bottomclip)
sofar = 0
ptr = 1
while sofar < bottomcount
  sofar += pixmax[ptr]
  mapto[ptr] = 0
  ptr += 1
end

bottomptr = ptr
print("Bottom clip level = ", bottomptr)
