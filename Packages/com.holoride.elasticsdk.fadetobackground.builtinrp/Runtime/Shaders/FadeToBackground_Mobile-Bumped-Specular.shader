// Modified by (c) holoride GmbH. All Rights Reserved.

// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Simplified Bumped Specular shader. Differences from regular Bumped Specular one:
// - no Main Color nor Specular Color
// - specular lighting directions are approximated per vertex
// - writes zero to alpha channel
// - Normalmap uses Tiling/Offset of the Base texture
// - no Deferred Lighting support
// - no Lightmap support
// - fully supports only 1 directional light. Other lights can affect it, but it will be per-vertex/SH.

Shader "FadeToBackground/Mobile|Bumped Specular" {
Properties {
    [PowerSlider(5.0)] _Shininess ("Shininess", Range (0.03, 1)) = 0.078125
    _MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
    [NoScaleOffset] _BumpMap ("Normalmap", 2D) = "bump" {}
}
SubShader {
    Tags { "RenderType"="Opaque" "FadeToBackgroundRole"="Opaque" }
    LOD 250

CGPROGRAM
#pragma surface surf MobileBlinnPhong exclude_path:prepass nolightmap noforwardadd halfasview interpolateview keepalpha vertex:Vert finalcolor:FinalColor 
#pragma target 3.0

inline fixed4 LightingMobileBlinnPhong (SurfaceOutput s, fixed3 lightDir, fixed3 halfDir, fixed atten)
{
    fixed diff = max (0, dot (s.Normal, lightDir));
    fixed nh = max (0, dot (s.Normal, halfDir));
    fixed spec = pow (nh, s.Specular*128) * s.Gloss;

    fixed4 c;
    c.rgb = (s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec) * atten;
    UNITY_OPAQUE_ALPHA(c.a);
    return c;
}

sampler2D _MainTex;
sampler2D _BumpMap;
half _Shininess;

struct Input {
    float2 uv_MainTex;
    float2 viewPosXZ;
    UNITY_FOG_COORDS(0)
};

float4 _FadeToBackground_CameraPosition;
half _FadeToBackground_OpaqueDistanceSquared;
half _FadeToBackground_TransparentDistanceSquared;
half _FadeToBackground_Opacity = 1;

void Vert (inout appdata_full v, out Input data) {
    UNITY_INITIALIZE_OUTPUT(Input, data);
    float4 clipPos = UnityObjectToClipPos(v.vertex);
    UNITY_TRANSFER_FOG(data, clipPos);
    data.viewPosXZ = mul(unity_ObjectToWorld, v.vertex).xz - (_FadeToBackground_CameraPosition).xz;
}

void FinalColor(Input IN, SurfaceOutput o, inout fixed4 color) {
     UNITY_APPLY_FOG(IN.fogCoord, color);
     half fade = _FadeToBackground_Opacity * saturate((_FadeToBackground_TransparentDistanceSquared - dot(IN.viewPosXZ, IN.viewPosXZ)) / (_FadeToBackground_TransparentDistanceSquared - _FadeToBackground_OpaqueDistanceSquared));
     color *= fade;
}

void surf (Input IN, inout SurfaceOutput o) {
    fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
    o.Albedo = tex.rgb;
    o.Gloss = tex.a;
    o.Alpha = tex.a;
    o.Specular = _Shininess;
    o.Normal = UnpackNormal (tex2D(_BumpMap, IN.uv_MainTex));
}
ENDCG
}

FallBack "Mobile/VertexLit"
}
