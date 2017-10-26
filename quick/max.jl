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
        final = view(reinterpret(what, img), 1:3, :, :)
        prepped = true
        print("Set base image\n")
    else
        final = max(final, view(reinterpret(what, img), 1:3, :, :))
    end
end

if what == UInt16
    saveit = colorview(RGB{N0f16}, final[1:3, :, :])
elseif what == UInt8
    saveit = colorview(RGB{N0f8}, final[1:3, :, :])
end

filen = shift!(args)
save(filen, saveit)
