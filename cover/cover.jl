using GLMakie
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
fig = Figure(size=(2400, 2400), fontsize=22, backgroundcolor="#371135")
ax = Axis3(fig[1, 1], aspect=:equal, perspectiveness=1, elevation=π / 5,
    zgridcolor=:white, ygridcolor=:white, xgridcolor=:white, xlabel="Longitude", ylabel="Latitude")
xlims!(ax, extrema(x)...)
ylims!(ax, extrema(y)...)
zlims!(ax, 0, zmax + 100)
sm = surface!(ax, x, y, dem; colormap=cmap, colorrange=(zmin, zmax))
contour!(ax, x, y, dem; levels=100, linewidth=0.1, color=:white,
    colorrange=(zmin, zmax), transparency=true)
save("test.png", ax.scene; px_per_unit=2)
