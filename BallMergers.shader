Shader "Hamilt79/BallMergers"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Noise ("Noise", 2D) = "white" {}
        [ToggleUI] _UseTex ("Use Tex", Float) = 0
    }
    SubShader
    {
        // Batching would make this stop working
        Tags { "DisableBatching" = "True" }
        // No culling or depth
        Cull Off
        ZWrite On

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
			#pragma multi_compile_instancing

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID 
            };

            // Check if two xyz locations are equal within a tolerance
            bool equal_check(float3 f1, float3 f2, float tolerance) {
                return (abs(distance(f1, f2)) < tolerance);
            }

            v2f vert (appdata v)
            {
                v2f o;
                // Ensure instancing is enabled before using functions
                #ifdef UNITY_INSTANCING_ENABLED
                // Setup currnet instance
                UNITY_SETUP_INSTANCE_ID(v);
                // Transfer it to output struct
    			UNITY_TRANSFER_INSTANCE_ID(v, o);
                // Max amount of balls
                const int len = 20;
                // Make array with max amount
                float3 cube_positions[len];
                // Make array of skipped bools with amount
                bool skipped[len];
                // Get world position
                float3 wposx = float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]);
                for (int idx = 0; idx < unity_InstanceCount; idx++)
                {
                    v2f dummy;
                    dummy.instanceID = idx;
                    // Change the current matricies to the dummy's values
                    UNITY_SETUP_INSTANCE_ID(dummy);
                    // Get world position of dummy
                    float3 wpos = float3(unity_ObjectToWorld[0][3], unity_ObjectToWorld[1][3], unity_ObjectToWorld[2][3]);
                    // Set it's position
                    cube_positions[idx] = wpos;
                }
                // Set global values back to the current vert struct
                UNITY_SETUP_INSTANCE_ID(v);
                // Convert local space to world space
                v.vertex = mul(unity_ObjectToWorld, v.vertex);
                const float cutoff = 0.7;
                float numOfBallsNear = 1;
                // for each instance currently available
                // unity_InstanceCount is a global that tracks the number of shared instances
                for (int i = 0; i < unity_InstanceCount; i++){
                    float dist = distance(v.vertex, cube_positions[i]);
                    // Checks if the balls are the same, and if so continue so we dont make them converge on themselves
                    if((cube_positions[i].x == 0 && cube_positions[i].y == 0 && cube_positions[i].z == 0) || equal_check(cube_positions[i].xyz, wposx.xyz, 0.0001) || dist >= cutoff){
                        continue;
                    }
                    numOfBallsNear++;
                }
                // We needed the first loop so we could clamp the ball distance change to the number of balls available
                // This makes it so the balls are evenly distributed when pulling on each other 
                float max = 1.0 / numOfBallsNear;
                for (int i = 0; i < unity_InstanceCount; i++){
                    float dist = distance(v.vertex, cube_positions[i]);
                    if((cube_positions[i].x == 0 && cube_positions[i].y == 0 && cube_positions[i].z == 0) || equal_check(cube_positions[i].xyz, wposx.xyz, 0.0001) || dist >= cutoff){
                        continue;
                    }
                    dist /= cutoff;
                    dist = cutoff - dist;
                    dist = clamp(dist, 0.0, max);
                    v.vertex.xyz = lerp(v.vertex.xyz, cube_positions[i].xyz, dist);
                    
                }
                v.vertex = mul(unity_WorldToObject, v.vertex);
                #endif
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _Noise;
            float _UseTex;
            float _NoiseAmount;
            float _VRChatMirrorMode;

            fixed4 frag (v2f i) : SV_Target
            {
                #ifdef UNITY_INSTANCING_ENABLED
                UNITY_SETUP_INSTANCE_ID(i);
                // Don't show up in VRC mirror since it can cause distortions
                if(_VRChatMirrorMode != 0) {
                    discard;
                }
                if (_UseTex) {
                    float noise = tex2D(_Noise, i.uv) * _NoiseAmount + 1;
                    //i.uv.x += sin(i.uv.x) + _Time.y * noise;
                    //i.uv.y += cos(i.uv.y) + _Time.y * noise;
                    i.uv.x += sin(i.uv.x * noise) * _Time.y * 0.05;
                    i.uv.y += cos(i.uv.y * noise) * _Time.y * 0.05;
                    return tex2D(_MainTex, i.uv);
                }
                // Change color depending on instanceID
                // This just makes it look colorful and gives a good visual representation
				if (i.instanceID == 0){
                    return float4(1,0,0,1);
                } else if (i.instanceID == 1){
                    return float4(0,1,0,1);
                } else if (i.instanceID == 2){
                    return float4(0,0,1,1);
                } else if (i.instanceID == 3){
                    return float4(1,1,0,1);
                } else if (i.instanceID == 4){
                    return float4(0,1,1,1);
                } else if (i.instanceID == 5){
                    return float4(1,0,1,1);
                }
                #endif
    			return float4(1,1,1,1);

            }
            ENDCG
        }
    }
}
