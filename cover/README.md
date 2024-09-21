# Making the cover

The cover is made as an A4 in Illustrator, with the title set in Tamil NM Bold 48pt, compressed by 40 to look like the Julia logo (https://github.com/JuliaLang/julia-logo-graphics?tab=readme-ov-file#construction-the-julia-language-logo). The logo is https://github.com/JuliaLang/julia-logo-graphics/blob/master/images/julia-logo-dark.svg.

The graphic is made by running the `cover.jl` file. Specifically what we see is the CopernicusDEM elevation model around Prague (where this book was born), both as a surface, as its white contours. No GeoMakie is used.

The author names are set in Montserrat 18pt.

Finally the cover is exported as png, `pngquant` is run for compression.

## Improvements
- [ ] Ditch Illustrator
- [ ] Fix labels intersecting ticks
- [ ] Improve surface (maybe rotate to the right as well)

