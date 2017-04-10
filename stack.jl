function verify(imagelist)
  dims = ""
  depth = ""
  mode = ""
  ptr = 1
  while ptr <= length(imagelist)
    wand = MagickWand()
    ImageMagick.pingimage(wand, imagelist[ptr])
    dmode = getimagecolorspace(wand)
    ddepth = getimagedepth(wand)
    ddims = size(wand)
    if mode == ""
      mode = dmode
    elseif mode != dmode
      println("Mode of ", imagelist[ptr], " is ", dmode, ", which doesn't match mode ", mode, " of the first image.")
      println("Exiting")
      exit(-1)
    end

    if depth == ""
      depth = dmode
    elseif depth != dmode
      println("Depth of ", imagelist[ptr], " is ", dmode, ", which doesn't match depth ", depth, " of the first image.")
      println("Exiting")
      exit(-1)
    end

    if dims == ""
      dims = ddims
    elseif dims != ddims
      println("Shape of ", imagelist[ptr], " is ", ddims, ", which doesn't match shape ", shape, " of the first image.")
      println("Exiting")
      exit(-1)
    end
    if verbose
      println("verified ", imagelist[ptr])
    end
    ptr += 1
  end
end

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

arglist = ARGS

approach = 1 # mean by default
nomen = "mean"
verbose = false
oname = ""
filelist = String[]
while length(arglist) > 0
  opt = shift!(arglist)
  if opt == "-mean"
    approach = 1
    nomen = "mean"
  elseif opt == "-max"
    approach = 2
    nomen = "max"
  elseif opt == "-min" # why?
    approach = 3
    nomen = "min"
  elseif opt == "-sigma" # sigma
    approach = 4
    nomen = "sigma clipped"
    sigma = 1 # will overwrite in a minute if specified in the command line
    if length(arglist) > 0 # see if they gave an argument
      text = shift!(arglist)
      x = tryparse(Float16, text)
      if isnull(x)
        unshift!(arglist, text)
      else
        sigma = x
        approach = 4
      end
    end
  elseif opt == "-o"
    if length(arglist) > 0
      oname = shift!(arglist)
    else
      println("-o specified but no filename")
      exit(-1)
    end
  elseif opt == "-v"
    verbose = true
  elseif opt == "-"
    println("Unknown option $opt")
    exit(-1)
  else
    if length(arglist) == 0 && oname == "" # last name is output file if not otherwise specified
      oname = opt
    else
      filelist = push!(filelist, opt)
    end
  end
end

if verbose
  println("Verifying that input files exist... ")
end

for fname in filelist
  if !isfile(fname)
    println("File does not exist: $fname")
    exit(-1)
  end
end

if verbose
  println("OK!")
end

using ImageMagick

if verbose
  print("\nVerifying that input file formats match... ")
end

verify(filelist)

if verbose
  println("OK!")
end

println("\nApplying ", nomen, " to ", length(filelist), " input files and saving to ", oname)

using Images
names = filelist
first = true
what = nothing
sums = nothing
count_ = length(filelist)
while length(names) > 0
  fname = shift!(names)
  if verbose
    print("Loading ", fname , "... ")
  end
  img =  load(fname)
  if isnull(img)
    println("$fname failed to load")
    exit(-1)
  end
  sz = size(img)
  if first
    szx = sz[1]
    szy = sz[2]
    what = getdepth(typeof(img))
    if verbose
      println("First image is $szx x $szy")
    end
  elseif sz[1] != szx || sz[2] != szy
    println("$name has size ", sz[1], "x", sz[2], ", which doesn't match initial size $szx x $szy")
    exit(-1)
  end

  img = reinterpret(what, img)
  img = img[1:3, :, :]
  println(size(img), " ", typeof(img))
  if verbose
    print("converting to floats... ")
  end
  img = map(Float32, img)
  if verbose
    print("merging... ")
  end
  if approach == 1 || approach == 4
    if first
      sums = zeros(Float32, size(img))
    end
    sums .+= img
  elseif approach == 2
    if first
      maxes = img
    else
      mat = img .> maxes
      maxes[mat] = img[mat]
    end
  elseif approach == 3
    if first
      mins = img
    else
      mat = img .< mins
      mins[mat] = img[mat]
    end
  end
  if approach == 4
    if first
      sumsq = zeros(Float32, size[img])
    end
    sumsq .+= img .^ 2
  end
  first = false
  if verbose
    println("Done!")
  end
end

if approach == 1
  println(size(sums), " ", typeof(sums))
  sums ./= count_
  if what == UInt16
    sums = map(x -> floor(UInt16, x), sums)
    img = colorview(RGB{N0f16}, sums)
  elseif what == UInt8
    img = map(x -> floor(UInt8, x), sums)
    img = colorview(RGB{N0f8}, img)
  end
  save(oname, img)
elseif approach == 2
  save(oname, maxes)
elseif approach == 3 # why?
  save(oname, mins)
elseif approach == 4 #
  println("Um ... this doesn't work yet")
else
  println("How did approach get set to $approach?")
  exit(-1)
end
