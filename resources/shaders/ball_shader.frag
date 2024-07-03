#version 330 core

in vec2 uv;
in vec4 fragColor;
out vec4 finalColor;

uniform sampler2D texture1;
uniform vec3 iRotation; // rotation angles in radians

#define PI 3.14159265359

mat3 rotateXYZ(vec3 angle) {
    vec3 c = cos(angle);
    vec3 s = sin(angle);
    
    mat3 rotX = mat3(1, 0, 0, 0, c.x, -s.x, 0, s.x, c.x);
    mat3 rotY = mat3(c.y, 0, s.y, 0, 1, 0, -s.y, 0, c.y);
    mat3 rotZ = mat3(c.z, -s.z, 0, s.z, c.z, 0, 0, 0, 1);
    
    return rotZ * rotY * rotX;
}

float srgbToLinear(float srgb) {
    return mix(
        pow(srgb, float(2.2)),
        srgb * 0.305 + 0.45,
        step(0.04045, srgb)
    );
}

float linearToSrgb(float linear) {
    return mix(
        pow(linear, 1.0 / 2.2),
        linear * 1.055 - 0.055,
        step(0.0031308, linear)
    );
}

void main()
{
    float scale = 1.5;

    vec2 new_uv = floor(uv * 28) / 28;
    new_uv += 1.0 / (28.0 * 2);

    
    // Convert UV to 3D point on a sphere
    vec2 sphereUV = (new_uv * 2.0 - 1.0) * scale;
    float x = sphereUV.x;
    float y = sphereUV.y;
    float z2 = 1.0 - min(1.0, dot(sphereUV, sphereUV));
    
    float z = sqrt(z2);
    vec3 spherePoint = vec3(x, y, z);
    
    // Normalize the point to ensure it's on the sphere surface
    vec3 normal = normalize(spherePoint);
    
    // Calculate rotation matrix
    mat3 rotation = rotateXYZ(iRotation);
    
    // Rotate the sphere point for texture mapping
    vec3 rotatedSpherePoint = rotation * spherePoint;
    
    // Calculate texture coordinates using rotated point
    vec2 finalUV = vec2(
        atan(rotatedSpherePoint.z, rotatedSpherePoint.x) / (2.0 * PI) + 0.5,
        asin(rotatedSpherePoint.y) / PI + 0.5
    );
    finalUV.x = 1.0 - abs(mod(finalUV.x * 2, 2.0) - 1.0);
    
    vec4 texColor = texture(texture1, finalUV);

    texColor.rgb *= fragColor.rgb;
    
    // Lighting calculation (using unrotated normal)
    vec3 lightDir = normalize(vec3(1.5, 1.0, 1.0)); // Light direction in world space
    float diffuse = max(dot(normal, lightDir), 0.0);
    //smooth out light intensity
    diffuse = linearToSrgb(diffuse);
    float ambient = 0.5; // Ambient light intensity
    vec3 viewDir = vec3(0.0, 0.0, 1.0); // Assuming the view is always from positive z
    vec3 reflectDir = reflect(-lightDir, normal);
    float specular = pow(max(dot(viewDir, reflectDir), 0.0), 32.0);
    
    vec3 litColor = texColor.rgb * (diffuse + ambient) + vec3(0.5) * specular;
    
    float distFromCenter = length(sphereUV);
    float alpha = smoothstep(1.0, 0.99, distFromCenter);
    
    vec2 shadowOffset = vec2(-lightDir.x, -lightDir.y) * 0.05; // Reduced from 0.1 to 0.05
    vec2 shadowUV = new_uv - vec2(0.5) - shadowOffset;
    float shadowDistance = length(shadowUV) * 2.2; // Increased from 1.9 to 2.2
    
    float shadowSoftness = 1.0; // Increased from 0.2 to 0.3
    float shadow = 1.0 - smoothstep(1.0 - shadowSoftness, 1.0, shadowDistance);
    shadow *= 0.9; // Reduce shadow intensity by half
    
    litColor = mix(litColor, vec3(0.0), (1.0 - alpha));
    
    finalColor = vec4(litColor * fragColor.rgb, alpha + shadow * (1.0 - alpha));
}