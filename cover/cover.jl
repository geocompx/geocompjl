using CairoMakie, MakieTeX
using Rasters
using ArchGDAL
using Stencils
using Statistics

dir = @__DIR__

# Load the DEM data and smooth it a bit
dem = Raster(joinpath(dir, "copdem_prague.tif"))
dem2 = mapstencil(mean, Moore(1), dem)  # Smooth the DEM slightly for better visuals
mask = dem2 .<= (dem .- 10)  # Ensure no negative artifacts from smoothing
dem2[mask] .= dem[mask]  # Replace only the problematic areas (at the edges)
dem = dem2

# Close any open screens and set backend
CairoMakie.activate!()

x = lookup(dem, X) # longitude
y = lookup(dem, Y) # latitude
zmin, zmax = minimum(dem), maximum(dem)
cmap = :viridis

set_theme!(merge(
    theme_dark(),
    Attributes(;
        Heatmap=(; rasterize=2),
        Surface=(; rasterize=2),
        color=:white,
        linecolor=:white,
    )))

fig = Figure(
    size=(700, 1000),
    fontsize=16,
    backgroundcolor="#371135"  # Julia purple background
)

title_ax = Axis(
    fig[1, 1];
    backgroundcolor=:transparent,
    height=160
)
hidedecorations!(title_ax)
hidespines!(title_ax)

title = text!(title_ax,
    "Geocomputation with",
    position=(0.5, 0.75),
    align=(:center, :center),
    fontsize=54,
    font=joinpath(@__DIR__, "TamilMN-Bold.ttf"),
    color=:white, space=:relative, )

svg = SVGDocument(read(download("https://raw.githubusercontent.com/JuliaLang/julia-logo-graphics/refs/heads/master/images/julia-logo-dark.svg"), String))
svg_plot = teximg!(title_ax, svg, position=(0.55, 0.50), align=(:center, :center), space=:relative, scale=0.40)

# Main terrain visualization
terrain_ax = Axis3(
    fig[2, 1],
    aspect=:equal,
    perspectiveness=1,
    elevation=π / 7,
    zgridcolor=:white,
    ygridcolor=:white,
    xgridcolor=:white,
    xlabel="Longitude",
    ylabel="Latitude",
    height=600,
    xspinecolor_1=:white,
    yspinecolor_1=:white,
    zspinecolor_1=:white,
    xspinecolor_2=:white,
    yspinecolor_2=:white,
    zspinecolor_2=:white,
    xspinecolor_3=:white,
    yspinecolor_3=:white,
    zspinecolor_3=:white,
);
hidedecorations!(terrain_ax; grid=false, label=false);


xlims!(terrain_ax, extrema(x)...)
ylims!(terrain_ax, extrema(y)...)
zlims!(terrain_ax, 0, zmax + 100)

# Add contour lines for depth
cp = contour!(
    terrain_ax, dem;
    levels=50,
    linewidth=0.2,
    color=:white,
    colorrange=(zmin, zmax),
    transparency=false,
    alpha=0.3
)

# Create surface plot
sp = surface!(
    terrain_ax, dem;
    colormap=cmap,
    colorrange=(zmin, zmax),
    shading=NoShading
)

# ==============================================================================
# AUTHORS SECTION
# =============================================================================

authors_ax = Axis(
    fig[3, 1];
    backgroundcolor=:transparent,
    height=80
)
hidedecorations!(authors_ax)
hidespines!(authors_ax)

# Author text
authors_text = text!(
    authors_ax,
    "Maarten Pronk, Rafael Schouten,\nAnshul Singhvi, and Felix Cremer",
    position=(0.5, 0.6),
    fontsize=18,
    font="Arial Bold",
    align=(:center, :center),
    color=:white,
    space=:relative
)

# Add subtitle indicating the series
series_text = text!(
    authors_ax,
    "Part of the geocompx series",
    position=(0.5, 0.2),
    fontsize=14,
    font="Arial",
    align=(:center, :center),
    color=:white,
    space=:relative
)

# Ensure proper spacing between sections
rowgap!(fig.layout, 1, 20)  # gap between title and terrain
rowgap!(fig.layout, 2, 20)  # gap between terrain and authors

display(fig)

save(joinpath(dir, "geocomputation_julia_cover.pdf"), fig; px_per_unit=3)
save(joinpath(dir, "geocomputation_julia_cover.png"), fig; px_per_unit=2)
