# Text

- Use one line per sentence during development for ease of tracking changes
- Leave a single empty line space before and after each code chunk
- Format content as follows: 
    - **PackageName.jl**
    - `class_of_object`
    - `function_name()`
- Spelling: use `en-us`
- Use of `\index{}` is recommended

# Code

- ` = ` , ` > `, etc. - spaces around operators
- When indenting your code, use two spaces [TODO: should we use four spaces?]

# Comments

Comment your code unless obvious because the aim is teaching.
Use capital first letter for full-line comment:

```r
# Create object x
x = 1:9
```

Do not capitalize comment for end-of-line comment:

```r
y = x^2 # square of x
```

# Captions

Captions should not contain any markdown characters, e.g. `*` or `_`. 
References in captions also should be avoided.

# Figures

Names of the figures should contain a chapter number, e.g. `04-world-map.png` or `11-population-animation.gif`.

# File names

- Minimize capitalization: use `file-name.rds` not `file-name.Rds`
- `-` not `_`: use `file-name.rds` not `file_name.rds`
