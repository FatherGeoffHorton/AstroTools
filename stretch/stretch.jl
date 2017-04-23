
###############################################################################
# DATA DEFINITIONS                                                            #
# {red|green|blue}map = current value of each pixel                           #
# {red|green|blue}counts = pixels in each bin                                 #
# {red|green|blue}vars: red[1000] = what 1000 mapped to with this transform   #
###############################################################################
########################## defaults ##############################################

obase = "none"  # default output base file name

rootpower    = 6.0      # default power factor: 1/rootpower for all iterations
rootiter     = 1        # number of iterations on applying rootpower - sky
rootpower2   = 1.0      # if rootiter =2 use this power on iteration 2 if the user sets it >1
pcntclip     = 0.005    # default percent clip level = total pixels * pcntclip/100

colorcorrect = 1        # default is to docolor correction.  (turn off to see the difference)

colorenhance = 1.0      # default enhancement value.
tonecurve    = 0        # no application odf a tone curve
specprhist   = 0        # no output histogram to specpr file
cumstretch   = 0        # do not do cumulative histogram stretch after rootpower
skylevelfactor = 0.06   # sky level relative to the histogram peak  (was 0.03 v0.88 and before)
rgbskylevel   = 1024.0    # desired  on a 16-bit  0 to 65535 scale
rgbskylevelrs = 4096.0    # desired  on output root stretched image 16-bit  0 to 65535 scale
zeroskyred    = 4096.0    # desired zero point on sky, red   channel
zeroskygreen  = 4096.0    # desired zero point on sky, green channel
zeroskyblue   = 4096.0    # desired zero point on sky, blue  channel
scurve        = 0         # no s-curve application
setmin        = 0         # no modification of the minimum
setminr = 0.0  # minimum for red
setming = 0.0  # minimum for green
setminb = 0.0  # minimum for blue
idisplay = 0   # do not display the final image
jpegonly = 0   # do not do jpeg only (will do jpeg + 16-bit png)
saveinputminussky  = 0  #  save input image - sky

debuga  = 0  # set to 1 for debugging, or 0 for none
doplots = 0  # show plots of histograms

function printhelp()
	println("      ERROR: need command line arguments")
	println("form:")
	println("      rnc-color-stretch   input_16bit_file [-rootpower x.x]  [-percent_clip p.p]")
	println("                                   -obase filename_noextension] [-enhance factor] [-tone] [-debug]")
	println("                                    [-specpr spfile] [-cumstretch] [-skylevelfactor x.x]")
	println("                                    [-rgbskyzero x.x x.x x.x]")
	println("                                    [-setmin R G B]")
	println("                                    [-nocolorcoerect]")
	println("                                    [-scurve1|-scurv2|scurve3|scurve4]")
	println("                                    [-jpegonly]  [-display]")
  println("\n      -obase   outoput base file name")
	println("      -rootpower x.x  values 1.0 to 599.0, default =%f\n", rootpower)
	println("                     Use higher number to bring up the faint end more")
	println("      -rootpower2 x.x  Use this power on iteration 2 if the user sets it >1")
	println("      -rootiter   Number of iterations to apply rootpower - sky, default =1")
	println("      -percent_clip p.p  allow no more than this percent of pixels to be clipped at zero.  default = %f%%\n", pcntclip)
	println("                       Note: zeros are ignored")
	println("      -enhance factor is >= 0.1. Values below 1 desaturate, above saturate.  default = %6.2f\n", colorenhance)
	println("      -specpr spfile  This option isn't implemented")
	println("      -skylevelfactor  the sky histogram alignment level relative to peak histogram (0.000001 to 0.5)")
	println("                       skylevelfactor default = %f\n", skylevelfactor)
	#println("      -rgbskylevel  output image, neutralized dark sky DN level.  default= %f (OBSOLETE)\n", rgbskylevel)
	#println("                    NOTE: rgbskylevel gets overridden by rgbskyzero so is obsolete")
	println("      -rgbskyzero  final image zero point level.  default RGB= %8.1f %8.1f %8.1f\n", zeroskyred, zeroskygreen, zeroskyblue)
	println("                   In the core of the Milky Way, it might be something like the color of interstellar dust.")
	println("                   This might be something like 2500 4000 5500 (0 to 65535, 16-bit range)")
	println("      -cumulstretch do cumulative stretch after rootpower (not recommended)")
	println("      -scurve1  apply an s-curve stretch as last step")
	println("      -scurve2  apply a stronger s-curve stretch as last step")
	println("      -scurve3  apply s-curve1 then 2, then 1 again as last step")
	println("      -scurve4  apply s-curve1 then 2, then 1, then 2 again as last step")
	println("      -setmin R G B set minimum levels to the 3 (floating point) values for red, green, blue")
	println("                    typical is about 20 on a 0 - 255 scale for darkest sky")
	println("                                        = 65535 * 20/255 = 5140 on 16-bit scale")
	println("      -jpegonly   do jpeg output only, no 16-bt png")
	println("      -display    display the final image")
	println("      -plots      display plots of the RGB histograms at each stage--currently not implemented")
	println("      -debug          turn on debug info and write debug images--currently not implemented")
	println("      -nocolorcoerect turn off color correction to see the detrimental effect of stretching")
  println("\n  Example:")
	println("      rnc-color-stretch trestfile.tif -rootpower 6.0  -obase testresult4  -scurve1")
	exit(1)
end

args = ARGS
if length(args) == 0
  printhelp()
  exit(-1)
end
filename = shift!(args)
while length(args) > 0
  opt = shift!(args)
  if opt == "-rootpower"
    if length(args) == 0 then
      println("No value specified for rootpower")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Invalid argument to -rootpower: $text")
      exit(-1)
    elseif 1 <= x <= 599
      rootpower = x
      println("Root power is $x")
      rootpower2 = x
    else
      println("Rootpower is $x; must be between 1 and 599")
      exit(-1)
    end
  elseif opt == "-rootiter"
    if length(args) == 0 then
      println("No value specified for rootiter")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Int16, text)
    if isnull(x)
      println("Invalid argument to -rootiter: $text")
      exit(-1)
    elseif i == 1 || i == 2
      rootiter = i
      println("Doing $rootiter iterations over root")
    else
      println("Rootiter is $i; must be 1 or 2")
      exit(-1)
    end
  elseif opt == "-rootpower2"
    if length(args) == 0 then
      println("No value specified for rootpower2")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Invalid argument to -rootpower2: $text")
      exit(-1)
    elseif 1 <= x <= 599
      rootpower2 = x
      println("Rootpower2 is $x")
    else
      println("Rootpower2 is $x; must be between 1 and 599")
      exit(-1)
    end
  elseif opt == "-percentclip"
    if length(args) == 0 then
      println("No value specified for percentclip")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Invalid argument to -percentclip: $text")
      exit(-1)
    elseif 0 <= x <= 90
      pcntclip = x
      println("Clipping at $pcntclip%")
    else
      println("percentclip is $x; must be between 0 and 90")
      exit(-1)
    end
  elseif opt == "-obase"
    if length(args) == 0 then
      println("No value specified for obase")
      exit(-1)
    end
    obase = shift!(args)
    println("Base output file name = $obase")
  elseif opt == "-enhance"
    if length(args) == 0 then
      println("No value specified for enhance")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Invalid argument to -enhance: $text")
      exit(-1)
    else
      enhance = x
      println("Enhancing at $enhance\%")
    end
  elseif opt == "-setmin"
    if length(args) < 3
      println("-setmin requires three arguments")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("First argument to -setmin is $text, needs to be numeric")
      exit(-1)
    else
      setminr = x
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Second argument to -setmin is $text, needs to be numeric")
      exit(-1)
    else
      setming = x
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Third argument to -setmin is $text, needs to be numeric")
      exit(-1)
    else
      setminb = x
    end
    if 0 <= setminr <= 20000 &&
       0 <= setming <= 20000 &&
       0 <= setminb <= 20000
      setmin = 1
      println("Settting mins: $setminr, $setming, $setminb")
    else
      println("Arguments to -setmin must be between 0 and 2000.")
      println("Actual args were $setminr, $setming, $setminb")
      exit(-1)
    end
  elseif opt == "-skylevelfactor"
    if length(args) == 0 then
      println("No value specified for skylevelfactor")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Invalid argument to -skylevelfactor: $text")
      exit(-1)
    elseif 0.000001 <= x <= 0.7
      skylevelfactor = x
      println("Using skylevel factor $x")
    else
      println("Skylevel factor $x is out of range; should be 0.00001 to 0.7")
      exit(-1)
    end
  elseif opt == "-rgbskylevel"
    if length(args) == 0 then
      println("No value specified for rgbskylevel")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Invalid argument to -rgbskylevel: $text")
      exit(-1)
    end
    if 0.1 <= x <= 20000
      rgbskylevel = x
      println("Using rgbskylevel $x")
    else
      println("rgbskylevel out of range at $x; should be 0.1-20000")
      exit(-1)
    end
  elseif opt == "-rgbskyzero"
    if length(args) < 3
      println("-rgbskyzero requires three arguments")
      exit(-1)
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("First argument to -rgbskyzero is $text, needs to be numeric")
      exit(-1)
    else
      zeroskyred = x
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Second argument to -rgbskyzero is $text, needs to be numeric")
      exit(-1)
    else
      zeroskygreen = x
    end
    text = shift!(args)
    x = tryparse(Float16, text)
    if isnull(x)
      println("Third argument to -rgbskyzero is $text, needs to be numeric")
      exit(-1)
    else
      zeroskyblue = x
    end
    if 0 <= zeroskyred <= 25000 &&
       0 <= zeroskygreen <= 25000 &&
       0 <= zeroskyblue <= 25000
      println("zeroing sky: $zeroskyred, $zeroskygreen, $zeroskyblue") # just for something to do
    else
      println("Arguments to -rgbskyzero must be between 0 and 25000.")
      println("Actual args were $zeroskyred, $zeroskygreen, $zeroskyblue")
      exit(-1)
    end
  elseif opt == "-cumstretch"
    cumstretch = 1
    println("Will do cumulative stretch")
  elseif opt == "-debug"
    debuga = 1
    println("Warning: Debug flag enabled but no debugging routines implemented")
  elseif opt == "-display"
    idisplay = 1
    println("Will display final image")
  elseif opt == "-plots"
    doplots = 1
    print("Warning: Plots enabled but not implemented")
  elseif opt == "-jpegonly"
    jpegonly = 1
    println("Saving jpeg only, except it's not implemented")
  elseif opt == "-nocolorcorrect"
    colorcorrect = 0
    println("Color correct off")
  elseif opt == "-tone"
    tonecurve = 1
    println("Doing tone curve")
  elseif opt == "-scurve1"
    scurve = 1
    println("Applying s-curve 1")
  elseif opt == "-scurve2"
    scurve = 2
    println("Applying s-curves 1 & 2")
  elseif opt == "-scurve3"
    scurve = 3
    println("Applying s-curves 1, 2, and 1 again")
  elseif opt == "-scurve4"
    scurve = 4
    println("Applying s-curves, 1, 2, 1, 2")
  elseif opt == "-saveinputminussky"
    saveinputminussky = 1
    print("Saving input - sky not implemented")
  elseif opt == "-specpr"
    if len(args) == 0
      println("No file given for specpr")
      exit(-1)
    else
      specprhist = 1
      spfile = shift!(args)
      print("Would save histograms to specpr file spfile but it's not implemented")
    end
  elseif opt == "-help"
    printhelp()
    exit(0)
  else
    println("Unknown option: $opt")
    exit(-1)
  end
end

if obase == "none"
  reggie = match(r"([^.]*)\.", filename)
  if reggie == nothing
    println("Warning: Couldn't get a base file name from $filename")
  else
    obase = string(reggie[1], "-final")
  end
  println("Output file(s) will be called $obase")
end

print("Loading packages... ")
using Images, FileIO, StatsBase, ImageCore

# Plots is slow to load; don't load if we're not using it
if doplots == 1
  using Plots
  pyplot()
else # have to define a dummy function so that plotter() doesn't cause an error
  function plot(args...)
  end
end

# ImageView loads pretty fast, but still....
if idisplay == 1
  using ImageView
end

println("Done!")


redvals = 0
greenvals = 0
bluevals = 0 # to put these in the global namespace

function plotter(title)
  #=edges = (1:256) .* 256
  r = map(x -> log(x + 1), fit(Histogram, redcounts, edges).weights)
  g = map(x -> log(x + 1), fit(Histogram, greencounts, edges).weights)
  b = map(x -> log(x + 1), fit(Histogram, bluecounts, edges).weights)
  print(size(r))
  for i = 1:255
    println(i, ": ", r[i], ", ", g[i], " ", b[i])
  end
#  a = cat(2, r, g, b)
#  plot(a,legend = nothing, color=reshape([:red, :green, :blue], 1, 3), title = title)
#  gui()=#
end

function checksum(v)
  result = reduce($, 0, map(Int,map(floor, v)))
  return result
end

function remap()
  # This function needs to be optimized!
  # if redmap[1000] used to be 987, it becomes where redvals[987] is going
  println("Remapping.... ")
  global redcounts, redmap, greencounts, greenmap, bluecounts, bluemap
  global redvals, greenvals, bluevals
  redvals = map(x -> floor(UInt64, x), redvals)
  greenvals = map(x -> floor(UInt64, x), greenvals)
  bluevals = map(x -> floor(UInt64, x), bluevals)
  redmap = map(x -> redvals[x] + 1, redmap)
  greenmap = map(x -> greenvals[x] + 1, greenmap)
  bluemap = map(x -> bluevals[x] + 1, bluemap)
  println("recounting... ")
  newred = zeros(65536)
  newgreen = zeros(65536)
  newblue = zeros(65536)

  for i = 1:65536
    newred[redvals[i] + 1] += redcounts[i]
    newgreen[greenvals[i] + 1] += greencounts[i]
    newblue[bluevals[i] + 1] += bluecounts[i]
  end

  redcounts = newred
  greencounts = newgreen
  bluecounts = newblue
  println("Done!")
end


function showmeans()
  v = collect(0:65535)

  redmin = reduce(min, npix, v[redcounts .>0])
  greenmin = reduce(min, npix, v[greencounts .>0])
  bluemin = reduce(min, npix, v[bluecounts .>0])

  redmax = reduce(max, 0, v[redcounts .>0])
  greenmax = reduce(max, 0, v[greencounts .>0])
  bluemax = reduce(max, 0, v[bluecounts .>0])

  redmean = sum((0:65535).* redcounts) / npix
  greenmean = sum((0:65535) .* greencounts) / npix
  bluemean = sum((0:65535) .* bluecounts) / npix

  @printf "  red: min = %5d max = %5d mean = %7.1f\n" redmin redmax redmean
  @printf "green: min = %5d max = %5d mean = %7.1f\n" greenmin greenmax greenmean
  @printf " blue: min = %5d max = %5d mean = %7.1f\n" bluemin bluemax bluemean
end

function smoothsky()
  global redvals, greenvals, bluevals
  # histogram plotting disabled
  # now find the sky level on the left side of the histogram

  println("Calculating sky smoothing peaks")
  redacc = cumsum(redcounts)
  greenacc = cumsum(greencounts)
  blueacc = cumsum(bluecounts)
  smoothred = zeros(65536)
  smoothgreen = zeros(65536)
  smoothblue = zeros(65536)
  width = 300          # include this many bins on either side
  redpeak = 0
  maxred = 0
  greenpeak = 0
  maxgreen = 0
  bluepeak = 0
  maxblue = 0
  for i = 400:65500 # ends are left off to avoid clipping artifacts
    low = i - width - 1 < 1 ? 1 : i - width - 1
    high = i + width > 65536 ? 65536 : i + width
    smoothred[i] = (redacc[high] - redacc[low]) / (high - low)
    smoothgreen[i] = (greenacc[high] - greenacc[low]) / (high - low)
    smoothblue[i] = (blueacc[high] - blueacc[low]) / (high - low)
    if smoothred[i] > maxred
      maxred = smoothred[i]
      redpeak = i
    end
    if smoothgreen[i] > maxgreen
      maxgreen = smoothgreen[i]
      greenpeak = i
    end
    if smoothblue[i] > maxblue
      maxblue = smoothblue[i]
      bluepeak = i
    end
  end
  if redpeak == 0 || greenpeak == 0 || bluepeak == 0
    @printf "Max search failed red %d green %d blue %d\n" redpeak greenpeak bluepeak
    exit(-1)
  end
  println("\n     image histogram:    max bin    pixel count")
  @printf "                  red:   %d         %f\n" redpeak maxred
  @printf "                green:   %d         %f\n" greenpeak maxgreen
  @printf "                 blue:   %d         %f\n" bluepeak maxblue

  redsky = maxred * skylevelfactor
  greensky = maxgreen * skylevelfactor
  bluesky = maxblue * skylevelfactor
  redskybin = 0
  greenskybin = 0
  blueskybin = 0

  #find where redvals[i] >= greenske and redlevel[i-1] <= greensky
  for i = redpeak:-1:2
    if smoothred[i] >= greensky && smoothred[i - 1] <= greensky
      redskybin = i + 1
      break
    end
  end

  for i = greenpeak:-1:2
    if smoothgreen[i] >= greensky && smoothgreen[i - 1] <= greensky
      greenskybin = i + 1
      break
    end
  end

  for i = bluepeak:-1:2
    if smoothblue[i] >= greensky && smoothblue[i - 1] <= greensky
      blueskybin = i + 1
      break
    end
  end

  if redskybin == 0 || greenskybin == 0 || blueskybin == 0
    @printf "histogram sky level %f not found:\n" skylevelfactor
    @printf "     channels: red %d   green %d   blue %d\n" redskybin greenskybin blueskybin
    println("          Try increasing -rgbskyzero values\n")
    exit(-1)
  end

  println("Histogram dark sky level")
  println("\n                  bin      Number of pixels in bin")     # need to compute cumulative hstogram
  @printf "           red:   %d         %d\n" redskybin   smoothred[redskybin]
  @printf "         green:   %d         %d\n" greenskybin smoothgreen[greenskybin]
  @printf "          blue:   %d         %d\n" blueskybin  smoothblue[blueskybin]

  redskysub1 = redskybin - zeroskyred
  greenskysub1 = greenskybin - zeroskygreen
  blueskysub1 = blueskybin - zeroskyblue

	@printf "\nsubtract %7d from red   to make red   sky align with zero reference sky: %7.1f\n" redskysub1   zeroskyred
	@printf "subtract %7d from green to make green sky align with zero reference sky: %7.1f\n" greenskysub1 zeroskygreen
	@printf "subtract %7d from blue  to make blue  sky align with zero reference sky: %7.1f\n" blueskysub1  zeroskyblue

	#@printf "\nnow set the RGB sky zero level to %7.1f  %7.1f  %7.1f bin out of 65535\n", zeroskyred zeroskygreen zeroskyblue

  redvals = greenvals = bluevals = collect(0:65535)
  redvals = (redvals .- redskysub1) .* (65535 / (65535 - redskysub1))
  greenvals = (greenvals .- greenskysub1) .* (65535 / (65535 - greenskysub1))
  bluevals = (bluevals .- blueskysub1) .* (65535 / (65535 - blueskysub1))
  redvals[redvals .< 0] = 0
  greenvals[greenvals .< 0] = 0
  bluevals[bluevals .< 0] = 0
  redvals = floor(redvals)
  greenvals = floor(greenvals)
  bluevals = floor(bluevals)
  remap()

  println("sky adjusted")
  showmeans()
end
###### end of function smoothsky

function setmins()
  global redvals, greenvals, bluevals
  println("\nsetting minimum levels.")
  zx = 0.2
  redvals = collect(0:65535)
  screen = redvals .< setminr
  redvals[screen] = redvals[screen] .* zx .+ setminr
  greenvals = collect(0:65535)
  screen = greenvals .< setming
  greenvals[screen] = greenvals[screen] .* zx .+ setming
  bluevals = collect(0:65535)
  screen = bluevals .< setminb
  bluevals[screen] = bluevals[screen] .* zx .+ setminb
  remap()

end

print("Loading $filename... ")
tic()
img = load(filename)
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
npix = px * py
npixm = floor(npix * pcntclip / 100.0)
npixm = npixm < 1 ? 1 : npixm
@printf "\nImage size: %d x %d pixels, cut level = %d\n" px py npixm
img = reinterpret(UInt16, img)
imgr = reshape(img[1, :, :], npix)
imgg = reshape(img[2, :, :], npix)
imgb = reshape(img[3, :, :], npix)

#=
redcounts = fit(Histogram, imgr, 0:65536).weights
greencounts = fit(Histogram, imgg, 0:65536).weights
bluecounts = fit(Histogram, imgb, 0:65536).weights
=#
# still can't make this work right :(
redcounts = zeros(UInt32, 65536)
greencounts = zeros(UInt32, 65536)
bluecounts = zeros(UInt32, 65536)
for i = 1:npix
  redcounts[imgr[i] + 1] += 1
  greencounts[imgg[i] + 1] += 1
  bluecounts[imgb[i] + 1] += 1
end

println("Histogram loading time: ", toq())

plotter("initial")
if doplots == 1
  plotter("Initial")
end


# pixel values are off by one throughout calculations
# because of 1-base arrays

redmap = collect(1:65536)
greenmap = collect(1:65536)
bluemap = collect(1:65536)

print("\n\nInitial bounds and means:\n")
showmeans()

if tonecurve == 1
  print("\n\nApplying tone curve... ")
  b = 12
  c = 65535
  d = 12
  redvals = greenvals = bluevals = collect(0:65535)
  # factor = b * ((1 / d)) ^ ((val / c) ^ 0.4)
  # could probably be done in one statement but since it's only done once,
  # it's not time-critical and not worth the time to figure out
  f = (map( x-> x ^ 0.4, (collect(0:65535) ./ c)))
  f = map( x -> b * (1 / d) ^ x, f)
  redvals = floor(redvals .* f)
  greenvals = floor(greenvals .* f)
  bluevals = floor(bluevals .* f)
  println("Done!")
  remap()
  print("after tone curve:\n")
  showmeans()
end

alowred   = 0  # find the DN level which is the cut level
alowgreen = 0
alowblue  = 0
nred   = redcounts[1]     # number of pixels in histogram bin
ngreen = greencounts[1]
nblue  = bluecounts[1]

for i = 2:32000   # upper limit is more or less pulled out of the air
                  # don't need to look at the first element because it's already zero
  if alowred == 0
    nred = nred + redcounts[i]
    if nred > npixm
      alowred = i
    end
  end
  if alowgreen == 0
    ngreen = ngreen + greencounts[i]
    if ngreen > npixm
      alowgreen = i
    end
  end
  if alowblue == 0
    nblue = nblue + bluecounts[i]
    if nblue > npixm
      alowblue = i
    end
  end
  if alowred > 0 && alowgreen > 0 && alowblue > 0
    break
  end
end

@printf "\n\ncumulative histogram cut level (%f %% = %d pixels):\n" pcntclip floor(npixm)
@printf "           red:   %d  (%d pixels)\n" alowred nred
@printf "           green: %d  (%d pixels)\n" alowgreen ngreen
@printf "           blue:  %d  (%d pixels)\n" alowblue nblue

# reset dark sky
for pass = 1:2
  @printf "\n\ndark sky subtraction pass %d\n" pass
#  println("r g b checksums before ", checksum(redvals), " ", checksum(greenvals), " ", checksum(bluevals))
  smoothsky()
end

afr = map(x -> redmap[x + 1], imgr)
afg = map(x -> greenmap[x + 1], imgg)
afb = map(x -> bluemap[x + 1], imgb)
# assemble sky-subtracted image here

println("============= computing root stretch =============")
for pass = 1:rootiter
  if pass == 2
    x = 1 / rootpower2
  else
    x = 1 / rootpower
  end

  println("Root stretch pass $pass of $rootiter")
  redfloat = collect(1:65536) / 65536 # has a +1 built in
  greenfloat = collect(1:65536) / 65536
  bluefloat = collect(1:65536) / 65536
  redfloat = map(z -> z ^ x, redfloat)
  greenfloat = map(z -> z ^ x, greenfloat)
  bluefloat = map(z -> z ^ x, bluefloat)
  redfloat = redfloat .* 65535
  greenfloat = greenfloat .* 65535
  bluefloat = bluefloat .* 65535
#  remap()
  redmin = reduce(min, 100000, redfloat[redcounts .> 0])
  greenmin = reduce(min, 100000, greenfloat[greencounts .> 0])
  bluemin = reduce(min, 100000, bluefloat[bluecounts .> 0])
  bmin = min(redmin, greenmin, bluemin)
  println("redmin $redmin greenmin $greenmin bluemin $bluemin bmin $bmin")
  if bmin < 4096
    bminz = 0
  else
    bminz = bmin - 4096
  end
  println("Subtracting $bminz from root stretched image")
  redfloat = (redfloat .- bminz) / (65535 - bminz) * 65535
  greenfloat = (greenfloat .- bminz) / (65535 - bminz) * 65535
  bluefloat = (bluefloat .- bminz) / (65535 - bminz) * 65535
  redfloat[redcounts .== 0] = 0
  greenfloat[greencounts .== 0] = 0
  bluefloat[bluecounts .== 0] = 0
  redvals = map(x -> floor(UInt16, x), redfloat)
  greenvals = map(x -> floor(UInt16, x), greenfloat)
  bluevals = map(x -> floor(UInt16, x), bluefloat)
  remap()

  showmeans()

  for pass2 = 1:(rootpower > 60 ? 3 : 2)
    println("Smooth sky pass $pass2 within root stretch pass $pass")
    smoothsky()
  end
end

if scurve > 0
  println("========== Doing s-curve stretching ==========")
  for i = 1:scurve
    if i == 2 || i == 4
      xfactor = 3
      xoffset = 0.22
    else
      xfactor = 5
      xoffset = 0.42
    end

    scurvemin = (xfactor / (1.0 + exp(-1.0 * (0 - xoffset) * xfactor))) - (1.0 - xoffset)
    scurvemax = (xfactor / (1.0 + exp(-1.0 * (1 - xoffset) * xfactor))) - (1.0 - xoffset)
    scurveminsc = scurvemin / scurvemax

    println("s-curve pass $i")
    println("          xfactor     = $xfactor")
    println("          xoffset     = $xoffset")
    @printf "          scurvemin   = %8.4f\n" scurvemin
    @printf "          scurvemax   = %8.4f\n" scurvemax
    @printf "          scurveminsc = %8.4f\n" scurveminsc

    xo = 1 - xoffset

    redsc = (collect(0:65535) ./ 65535 .- xoffset) .* -xfactor
    redsc = map(exp, redsc)
    redsc = redsc .+ 1
    redsc = (xfactor ./ redsc) .- xo
    redsc = redsc ./ scurvemax .- scurveminsc
    redsc = 65535 .* redsc
    redvals = map(x -> floor(UInt64, x), redsc ./ (1 - scurveminsc))

    greensc = (collect(0:65535) ./ 65535 .- xoffset) .* -xfactor
    greensc = map(exp, greensc)
    greensc = greensc .+ 1
    greensc = (xfactor ./ greensc) .- xo
    greensc = greensc ./ scurvemax .- scurveminsc
    greensc = 65535 .* greensc
    greenvals = map(x -> floor(UInt64, x), greensc ./ (1 - scurveminsc))

    bluesc = (collect(0:65535) ./ 65535 .- xoffset) .* -xfactor
    bluesc = map(exp, bluesc)
    bluesc = bluesc .+ 1
    bluesc = (xfactor ./ bluesc) .- xo
    bluesc = bluesc ./ scurvemax .- scurveminsc
    bluesc = 65535 .* bluesc
    bluevals = map(x -> floor(UInt64, x), bluesc ./ (1 - scurveminsc))

    remap()

    println("\n")
    showmeans()
  end

  for j = 1:2
    println("Doing sky offset pass $j")
    smoothsky()
  end
end

if setmin > 0
  setmins()
end

#plotter("Before final load")
cr = map(x -> redmap[x + 1] - 1, imgr)
cg = map(x -> greenmap[x + 1] - 1, imgg)
cb = map(x -> bluemap[x + 1] - 1, imgb)
cr[cr .== 0] = 1
cg[cg .== 0] = 1
cb[cb .== 0] = 1

crmin = reduce(min, 65537, cr)
crmax = reduce(max, 0, cr)
crmean = mean(cr)

cgmin = reduce(min, 65537, cg)
cgmax = reduce(max, 0, cg)
cgmean = mean(cg)

cbmin = reduce(min, 65537, cb)
cbmax = reduce(max, 0, cb)
cbmean = mean(cb)

println("Image reloaded")
@printf "red   min = %d max = %d mean = %7.1f\n" crmin crmax crmean
@printf "green min = %d max = %d mean = %7.1f\n" cgmin cgmax cgmean
@printf "blue  min = %d max = %d mean = %7.1f\n" cbmin cbmax cbmean

if colorcorrect > 0
  println("\n ========== final color adjustment ==========")
  afr = afr .- zeroskyred
  afr[afr .< 10] = 10
  afg = afg .- zeroskygreen
  afg[afg .< 10] = 10
  afb = afb .- zeroskyblue
  afb[afb .< 10] = 10

  println("color adjustments")

  grratio = (afg ./ afr) ./ (cg ./ cr)
  brratio = (afb ./ afr) ./ (cb ./ cr)
  rgratio = (afr ./ afg) ./ (cr ./ cg)
  bgratio = (afb ./ afg) ./ (cb ./ cg)
  gbratio = (afg ./ afb) ./ (cg ./ cb)
  rbratio = (afr ./ afb) ./ (cr ./ cb)

  zmin = 0.2
  zmax = 1.0

  grratio[grratio .< zmin] = zmin
  grratio[grratio .> zmax] = zmax

  brratio[brratio .< zmin] = zmin
  brratio[brratio .> zmax] = zmax

  rgratio[rgratio .< zmin] = zmin
  rgratio[rgratio .> zmax] = zmax

  bgratio[bgratio .< zmin] = zmin
  bgratio[bgratio .> zmax] = zmax

  gbratio[gbratio .< zmin] = zmin
  gbratio[gbratio .> zmax] = zmax

  rbratio[rbratio .< zmin] = zmin
  rbratio[rbratio .> zmax] = zmax

  println("\nColor ratio images after constraint to interval ($zmin, $zmax)")
  g = summarystats(grratio)
  @printf "grratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(brratio)
  @printf "brratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(rgratio)
  @printf "rgratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(bgratio)
  @printf "bgratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(gbratio)
  @printf "gbratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(rbratio)
  @printf "rbratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean

  avgn = (cr .+ cg .+ cb) ./ (3 * 65535)
  avgn[avgn .< 0] = 0
  cmax = reduce(max, 0, avgn)
  if cmax < 1
    avgn ./= cmax
  end

  avgn .^= 0.2
  avgn .+= 0.3
  avgn ./= 1.3
  cmin = reduce(min, 65537, avgn)
  cmax = reduce(max, 0, avgn)
  cmean = mean(avgn)

  @printf "Color correction intensity min = %7.5f max = %7.5f mean = %7.5f\n" cmin cmax cmean

  cfactor = 1.2
  cfe = avgn .* (cfactor * colorenhance)
  grratio = 1 .+ cfe .* (grratio .- 1)
  brratio = 1 .+ cfe .* (brratio .- 1)
  rgratio = 1 .+ cfe .* (rgratio .- 1)
  bgratio = 1 .+ cfe .* (bgratio .- 1)
  gbratio = 1 .+ cfe .* (gbratio .- 1)
  rbratio = 1 .+ cfe .* (rbratio .- 1)

  println("Color ratio images after factors applied")
  g = summarystats(grratio)
  @printf "grratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(brratio)
  @printf "brratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(rgratio)
  @printf "rgratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(bgratio)
  @printf "bgratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(gbratio)
  @printf "gbratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean
  g = summarystats(rbratio)
  @printf "rbratio min = %7.3f, max = %7.3f, mean = %7.3f\n"  g.min g.max g.mean

  cmin = reduce(min, 65537, cfe)
  cmax = reduce(max, 0, cfe)
  cmean = mean(cfe)
  @printf "Color correction cfe min = %7.5f max = %7.5f mean = %7.5f\n" cmin cmax cmean

  println("Computing possible image sets")
  c2gr = cg .* grratio
  c3br = cb .* brratio
  c1rg = cr .* rgratio
  c3bg = cb .* bgratio
  c1rb = cr .* rbratio
  c2gb = cg .* gbratio

  println("Starting signal dependent color recovery")
  println("Processing $npix pixels....")
  decile = floor(npix / 10)
  pixelcount = decile
  for i = 1:npix
    pixelcount -= 1
    if pixelcount == 0
      println("Processing pixel $i of $npix...")
      pixelcount = decile
    end
    # I think this could be done with stacked ternary operators
    maxv = cr[i]
    maxch = 1
    if cg[i] > maxv
      maxv = cg[i]
      maxch = 2
    end
    if cb[i] > maxv
      # don't need the max value!
      maxch = 3
    end
    if maxch == 1
      cg[i] = floor(UInt16, c2gr[i])
      cb[i] = floor(UInt16, c3br[i])
    elseif maxch == 2
      cr[i] = floor(UInt16, c1rg[i])
      cb[i] = floor(UInt16, c3bg[i])
    else
      cr[i] = floor(UInt16, c1rb[i])
      cg[i] = floor(UInt16, c2gb[i])
    end
  end

  println("Color recovery complete")
end

if setmin > 0
  setmins()
end

smoothsky()
#=if cumstretch == 1
  println("Performing cumulative histogram strech")
  hist = fit(Histogram, [cr, cg, cb], 0:65536).weights
  #redcounts = fit(Histogram, imgr, 0:65536).weights
  cs = chist
  gap = 15000
  for i=1:65535
    ilow = i <= gap ? 1 : i - gap
    ihigh = i >= 65535 - gap ? 65535 : i + gap
    =#


cr[cr .< 0] = 0
cr[cr .> 65535] = 65535
cg[cg .< 0] = 0
cg[cg .> 65535] = 65535
cb[cb .< 0] = 0
cb[cb .> 65535] = 65535

finalr = reshape(map(x -> floor(UInt16, x), cr), px, py)
finalg = reshape(map(x -> floor(UInt16, x), cg), px, py)
finalb = reshape(map(x -> floor(UInt16, x), cb), px, py)
final = zeros(UInt16, 3, px, py)
final[1, :, :] = finalr
final[2, :, :] = finalg
final[3, :, :] = finalb

final = colorview(RGB{N0f16}, final)
if idisplay == 1
  imshow(final)
  println("Hit <Enter> to continue:")
  readline(STDIN)
end
#final = reinterpret()
oname = "$obase.png"
print("Saving $oname... ")
save(oname, final)
println("Done!")
