#version 330

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;

uniform mat4 mvp;
uniform vec2 spriteIndex;

out vec2 uv;
out vec4 fragColor;

void main()
{
    uv = vertexTexCoord;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
    fragColor = vertexColor;
}