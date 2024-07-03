#version 330

// Input vertex attributes
in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;

// Input uniform values
uniform mat4 mvp;
uniform vec2 spriteIndex;

// Output vertex attributes (to fragment shader)
out vec2 fragTexCoord;
out vec2 uv;
out vec4 fragColor;

void main()
{
    uv = vertexTexCoord;
    // Calculate final vertex position
    gl_Position = mvp * vec4(vertexPosition, 1.0);
    
    // Quantize the sprite index to ensure whole number selection
    vec2 quantizedIndex = floor(spriteIndex);
    
    fragTexCoord.x = (vertexTexCoord.x + quantizedIndex.x) / 24.0;
    fragTexCoord.y = (vertexTexCoord.y + quantizedIndex.y) / 24.0;
    
    // Pass through the vertex color
    fragColor = vertexColor;
}