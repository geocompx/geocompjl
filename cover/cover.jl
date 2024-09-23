using GLMakie, MakieTeX, Colors
using Rasters
using ArchGDAL
dir = @__DIR__

dem = Raster(joinpath(dir, "copdem_prague.tif"))

GLMakie.activate!()
GLMakie.activate!(ssao=true)

GLMakie.closeall() # close any open screen

x = lookup(dem, X) # if X is longitude
y = lookup(dem, Y) # if Y is latitude
zmin, zmax = minimum(dem), maximum(dem)
cmap = :viridis

set_theme!(theme_dark())
# backgroundcolor is julia purple with blacks set to 80% to match Python cover
fig = Figure(
    size=(500, 750) .* 2, 
    fontsize=22, 
    backgroundcolor=colorant"#371135"
);
ax = Axis3(
    fig[1, 1], 
    aspect=:equal, perspectiveness=1, 
    elevation=π / 5,
    zgridcolor=:white, ygridcolor=:white, xgridcolor=:white, 
    xlabel="Longitude", ylabel="Latitude"
)

xlims!(ax, extrema(x)...)
ylims!(ax, extrema(y)...)
zlims!(ax, 0, zmax + 100)
sp = surface!(
    ax, dem; 
    colormap=cmap, colorrange=(zmin, zmax),
)
# Fiddle with lighting in the surface plot
sp.diffuse[] = 0.9
# sp.shading[] = MultiLightShading
sp.shading[] = NoShading

# Construct contour lines
cp = contour!(
    ax, dem; 
    levels=100, linewidth=0.1, 
    color=:white, colorrange=(zmin, zmax), 
    transparency=true
)

# This makes sure that the screen is reconstituted
# and all rendering options are applied correctly.
GLMakie.closeall() # close any open screen

save("test.png", fig; px_per_unit=2)


# Test rendering parameters
oldspec = sm.specular[]
record(fig, "specular.mp4", LinRange(0, 1, 100)) do s
    sm.specular[] = s
end
sm.specular[] = oldspec

oldspec = sm.shininess[]
record(fig, "shininess.mp4", LinRange(1, 100, 100)) do s
    sm.shininess[] = s
end
sm.shininess[] = oldspec

oldspec = sm.diffuse[]
record(fig, "diffuse.mp4", LinRange(0, 1, 100)) do s
    sm.diffuse[] = s
end
sm.diffuse[] = oldspec



