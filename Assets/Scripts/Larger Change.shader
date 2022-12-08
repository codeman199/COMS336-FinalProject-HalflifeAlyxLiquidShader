Shader "Unlit/FX/Liquid"
{
    //Declaring starting properties for the material that is created
    //https://docs.unity3d.com/Manual/SL-Properties.html
    Properties
    {
        [HDR]_Tint ("Tint", Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        [HideInInspector] _WobbleX ("WobbleX", Range(-1,1)) = 0.0
        [HideInInspector] _WobbleZ ("WobbleZ", Range(-1,1)) = 0.0
        _NormalsDistortion ("Distort Liquid based on Normals", Range(0,1)) = 1.0
    }

    //SubShader (Used to define GPU settings and in this case, a shader program)
    //https://docs.unity3d.com/Manual/SL-SubShader.html
    SubShader
    {
        Tags {"Queue"="Geometry"  "DisableBatching" = "True" }

        Pass
        {
            Zwrite On
            Cull Off // we want the front and back faces
            AlphaToMask On // transparency

            CGPROGRAM
            #pragma vertex vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            //Providing vertex data to vertex programs
            //https://docs.unity3d.com/Manual/SL-VertexProgramInputs.html
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewDir : COLOR;
                float3 normal : COLOR2;
                float fillPosition : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float3 _FillAmount;
            float _WobbleX, _WobbleZ;
            float _NormalsDistortion;
            float4 _Tint;

            float4 RotateAroundYInDegrees (float3 vertex, float degrees)
            {
                float alpha = degrees * UNITY_PI / 180;
                float sina, cosa;
                sincos(alpha, sina, cosa);
                float2x2 m = float2x2(cosa, sina, -sina, cosa);
                return float4(vertex.yz , mul(m, vertex.xz)).xzyw ;
            }


            v2f vertexShader (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // get world position of the vertex - transform position
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex.xyz);
                float3 worldPosOffset = float3(worldPos.x, worldPos.y , worldPos.z) - _FillAmount;
                // rotate it around XY
                float3 worldPosX= RotateAroundYInDegrees((worldPosOffset),360);
                // rotate around XZ
                float3 worldPosZ = float3 (worldPosX.y, worldPosX.z, worldPosX.x);
                // combine rotations with worldPos, based on sine wave from script
                float3 worldPosAdjusted = worldPos + (worldPosX  * _WobbleX) + (worldPosZ* _WobbleZ);
                // how high up the liquid is
                o.fillPosition =  worldPosAdjusted.y - _FillAmount.y;
                o.viewDir = normalize(ObjSpaceViewDir(v.vertex));
                o.normal = v.normal;
                return o;
            }

            fixed4 fragmentShader (v2f i, fixed facing : VFACE) : SV_Target
            {
                // add velocity based deform, using the normals for a fresnel effect
                float movementFresnel = facing > 0 ? dot(i.normal, i.viewDir) : dot(-i.normal, -i.viewDir);
                float movingfillPosition = i.fillPosition + (saturate(movementFresnel * i.fillPosition) *(_WobbleX + _WobbleZ) * _NormalsDistortion);

                // sample the texture based on the fill line
                fixed4 col = tex2D(_MainTex, movingfillPosition) * _Tint;

                // Calculate edge
                float cutoffTop = step(movingfillPosition, 0.5);

                // Calculate liquid and require cutoff value
                float4 finalResult = cutoffTop * col;

                return finalResult;
            }
            ENDCG
        }

    }
}