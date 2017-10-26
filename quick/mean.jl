function getdepth(str)
  str = string(str)
  depth = match(r"(UInt\d+)", str)
  if depth == nothing
    println("Error: failed to determine depth from ", str)
    exit(-1)
  end
  if depth[1] == "UInt8"
    rslt = UInt8
  elseif depth[1] == "UInt16"
    rslt = UInt16
  else
    println("Can't handle color depth ", depth[1])
    exit(-1)
  end
  return rslt
end


using Images, ImageCore
args = ARGS
if length(args) < 2
  println("Need at least one input file and one output file.")
  exit(-1)
end

prepped = false
final = nothing
what = nothing
sums = nothing
counter = 0

while length(args) > 1
    filen = shift!(args)
    img = load(filen)
    if img == nothing
      println("Image failed to load.")
      exit(-1)
    end
    println("Loaded ", filen)
    if ~ prepped
        what = getdepth(typeof(img))
        sums = similar(img[1:3, : , : ], Int32)
        sums = view(reinterpret(what, img), 1:3, :, :)
        prepped = true
        print("Set base image\n")
    else
        sums = broadcast(+, sums, view(reinterpret(what, img), 1:3, :, :))
    end
    counter += 1
end

if what == UInt8
    multiplier = 255.0 / counter
else
    multiplier = 1.0 / counter
end
println("Converting for save")
saveit = broadcast(*, sums, multiplier)
saveint = similar(saveit, UInt16)
for I in eachindex(saveit)
#    println(saveit[I])
#    println(floor(saveit[I]))
#    println("---------")
    saveint[I] = convert(UInt16, floor(saveit[I]))
end

#saveint = broadcast(convert(UInt16), saveit)
saveint = colorview(RGB{N0f16}, saveint)

filen = shift!(args)
save(filen, saveint)
