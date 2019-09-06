#ifdef VERTEX
vec4 position( mat4 transform_projection, vec4 vertex_position )
{
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 orig = Texel(texture, texture_coords);

    float gray = dot(orig.rgb, vec3(0.299, 0.587, 0.114));

    orig.r = gray;
    orig.g = gray;
    orig.b = gray;

    return orig * color;
}
#endif
