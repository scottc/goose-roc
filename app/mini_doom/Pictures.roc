module [Atlas, empty]

Atlas : {
    width : U64,
    height : U64,
    pixels : List(U8), # RGBA
}

empty : Atlas
empty = {
    width: 2048,
    height: 4096,
    pixels: [],
}
