Shader "Custom/OriginalLiquid"
{
    Properties
    {
        [HDR]_Tint ("Tint", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [HideInInspector] _WobbleX ("WobbleX", Range(-1,1)) = 0.0
        [HideInInspector] _WobbleZ ("WobbleZ", Range(-1,1)) = 0.0
        _NormalsDistortion ("Distort Liquid based on Normals", Range(0,1)) = 1.0
        [HDR]_TopColor ("Top Color", Color) = (1,1,1,1)
        [HDR]_FoamColor ("Foam Line Color", Color) = (1,1,1,1)
        _Line ("Foam Line Width", Range(0,0.1)) = 0.0
        [HDR]_RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", Range(0,10)) = 0.0

        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200
        Cull Off
        CGPROGRAM

        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_fog

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        struct Output
        {
        };

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float4 RotateAroundYInDegrees (float3 vertex, float degrees)
        {
            float alpha = degrees * UNITY_PI / 180;
            float sina, cosa;
            sincos(alpha, sina, cosa);
            float2x2 m = float2x2(cosa, sina, -sina, cosa);
            return float4(vertex.yz , mul(m, vertex.xz)).xzyw;
        }

        Output vert (Input in)
        {

        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
