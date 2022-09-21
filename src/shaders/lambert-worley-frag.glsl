#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;
uniform sampler2D u_Texture;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

float rand1dTo1d(float value){
	float random = fract(sin(value + 0.546) * 143758.5453);
	return random;
}

// ------------------- FBM2D --------------------------
float random (vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

#define OCTAVES 6
float fbm (vec2 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}

// ------------------- FBM3D --------------------------
float hash(float h) {
	return fract(sin(h) * 43758.5453123);
}

float noise3d (vec3 x) {
	vec3 p = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);

	float n = p.x + p.y * 157.0 + 113.0 * p.z;
	return mix(
			mix(mix(hash(n + 0.0), hash(n + 1.0), f.x),
					mix(hash(n + 157.0), hash(n + 158.0), f.x), f.y),
			mix(mix(hash(n + 113.0), hash(n + 114.0), f.x),
					mix(hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}

#define OCTAVES 6
float fbm3d (vec3 st) {
    // Initial values
    float value = 0.0;
    float amplitude = .5;
    float frequency = 0.;
    //
    // Loop of octaves
    for (int i = 0; i < OCTAVES; i++) {
        value += amplitude * noise3d(st);
        st *= 2.;
        amplitude *= .5;
    }
    return value;
}
float suqare_wave(float x, float freq, float amplitude){
    return abs(mod(floor(x * freq), 2.0) * amplitude);
}

// --- worley
vec2 random2(vec2 p)
{
    return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
                          dot(p, vec2(269.5,183.3))))
                          * 43758.5453);
}

float noise1D( vec2 p ) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) *
                 43758.5453);
}

float WorleyNoise(vec2 uv)
{
    uv *= 0.8; // Now the space is 10x10 instead of 1x1. Change this to any number you want.
    vec2 uvInt = floor(uv); // grid cell which fragment lies
    vec2 uvFract = fract(uv); // uv lie in the cell
    float minDist = 1.0; // Minimum distance initialized to max.
    for(int y = -1; y <= 1; ++y) {
        for(int x = -1; x <= 1; ++x) {
            vec2 neighbor = vec2(float(x), float(y)); // Direction in which neighbor cell lies
            vec2 point = random2(uvInt + neighbor); // Get the Voronoi centerpoint for the neighboring cell
            //point += (0.5*sin(u_Time * 0.01)+0.5);
            vec2 diff = neighbor + point - uvFract; // Distance between fragment coord and neighbor’s Voronoi point
            float dist = length(diff);
            minDist = min(minDist, dist);
        }
    }
    return minDist;
}

float triangle_wave(float x, float per, float amp) {
    return 2.* abs(x / per - floor(x / per + 0.5)) * amp;
}

void main()
{
//     vec2 uv = -.5 + fs_Pos.xy / vec2(1080, 1080);

//     float delta = 0.001;
//     vec2 uv0x = uv + vec2(delta, 0.0);
//     vec2 uv1x = uv + vec2(-delta, 0.0);
// //    float slopeX = (1 - clamp(WorleyNoise(uv0x), 0.0, 1.0)) - (1 - clamp(WorleyNoise(uv1x), 0.0, 1.0));
//     float slopeX = clamp(WorleyNoise(uv0x), 0.0, 1.0) - clamp(WorleyNoise(uv1x), 0.0, 1.0);
//     vec2 uv0y = uv + vec2(0.0, delta);
//     vec2 uv1y = uv + vec2(0.0, -delta);
// //    float slopeY = (1 - clamp(WorleyNoise(uv0y), 0.0, 1.0)) - (1 - clamp(WorleyNoise(uv1y), 0.0, 1.0));
//     float slopeY = clamp(WorleyNoise(uv0y), 0.0, 1.0) - clamp(WorleyNoise(uv1y), 0.0, 1.0);
//     vec2 newUV = uv + vec2(slopeX, slopeY);

//     float worleynoise = 1.0 - WorleyNoise(fs_Pos.xy);
//     if(worleynoise < 0.9){
//         worleynoise = 0.0;
//     }

//     //vec4 col = vec4(1.0, 0.0, 0.0, 1.0) * worleynoise;

//     //out_Col = mix(col, vec4(0.0, 0.0, 0.0, 1.0), (1.0 - worleynoise));
//     out_Col = vec4(worleynoise, worleynoise, worleynoise, 1.0);

    // vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    // float dist = length(fs_Pos.xy) * 0.08;
    
    // vec2 dir = -normalize(fs_Pos.xy);

    // float fbm2d1 = fbm(fs_Pos.xy);

    // vec2 pos = fs_Pos.xy + dir * u_Time * 0.01;

    // float fbm2d = fbm(pos * 0.1);

    // float sw = suqare_wave(fbm2d, 3.0, 1.0);

    // // float noise = 0.0;
    // // if (fs_Pos.y >= 0.0 && fs_Pos.x >= 0.0){
    // //     noise = fbm3d(vec3(pos.x - u_Time * 0.01, pos.y - u_Time * 0.01, u_Time * 0.005)* 0.05);
    // // }
    // // else if(fs_Pos.y >= 0.0 && fs_Pos.x < 0.0){
    // //     noise = fbm3d(vec3(pos.x, pos.y - u_Time * 0.01, u_Time * 0.005)* 0.05);
    // // }
    // // else if(fs_Pos.y < 0.0 && fs_Pos.x < 0.0){
    // //     noise = fbm3d(vec3(pos.x + u_Time * 0.01, pos.y + u_Time * 0.01, u_Time * 0.005)* 0.05);
    // // }
    // // else {
    // //     noise = fbm3d(vec3(pos.x - u_Time * 0.01, pos.y + u_Time * 0.01, u_Time * 0.005)* 0.05);
    // // }
    // //float a = atan(pos.x,pos.y)+u_Time*0.01;
    // //noise = fbm(vec2(a, a));

    
    

    // vec4 texture = texture(u_Texture2D, vec2(fbm2d,fbm2d)); 

    // //fragColor = vec4(noise, noise, noise, 1.0);
    // fragColor = mix(texture, vec4(0.0, 0.0, 0.0, 1.0), dist);
    // //fragColor.r = pow(fragColor.r, dist*3.0);
    // //fragColor.g = pow(fragColor.g, dist*3.0);
    // //fragColor.b = pow(fragColor.b, dist*3.0);
    // //fragColor = mix(fragColor, vec4(0.0, 0.0, 0.0, 1.0), dist);
    // out_Col = fragColor;  

    float dist = length(fs_Pos.xy) * 0.08;

    float degree = atan(fs_Pos.y,fs_Pos.x)/3.14159;
    float amplitudeScaler = fbm(fs_Pos.xy);
    vec3 pos = vec3(fs_Pos.x + u_Time * 0.001, fs_Pos.y + u_Time * 0.003, fs_Pos.z + u_Time * 0.003) / vec3(0.3);
    float animateScaler = fbm3d (pos) * 7.0;

    float offset = triangle_wave(degree, 0.05, 0.2 * amplitudeScaler * animateScaler);
    
    vec4 texture = texture(u_Texture, vec2(amplitudeScaler,amplitudeScaler)); 

    vec4 fragColor = vec4(0.0, 0.0, 0.0, 1.0);
    if(dist < 0.6 + offset && dist >= 0.6){
        fragColor = texture ;
    }
    if(dist < 0.5 + offset && dist >= 0.5){
        fragColor = texture + vec4(0.2, 0.2, 0.0, 1.0);
    }
    if(dist < 0.3 + offset && dist >= 0.3){
        fragColor = texture + vec4(1.0, 1.0, 0.0, 1.0);
    }

    // float offset2 = triangle_wave(degree, 0.4, 0.2 * amplitudeScaler * animateScaler);
    // if(dist < 0.6 + offset2){
    //     fragColor = texture ;
    // }


    //fragColor = vec4(degree, degree, degree, 1.0);
    out_Col = fragColor; 

}
