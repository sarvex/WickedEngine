#include "globals.hlsli"
#include "ShaderInterop_EmittedParticle.h"
#include "emittedparticleHF.hlsli"

static const float3 BILLBOARD[] = {
	float3(-1, -1, 0),	// 0
	float3(1, -1, 0),	// 1
	float3(-1, 1, 0),	// 2
	float3(1, 1, 0),	// 4
};

StructuredBuffer<Particle> particleBuffer : register(t1);
StructuredBuffer<uint> culledIndirectionBuffer : register(t2);
StructuredBuffer<uint> culledIndirectionBuffer2 : register(t3);

VertextoPixel main(uint vid : SV_VertexID, uint instanceID : SV_InstanceID)
{
	ShaderGeometry geometry = EmitterGetGeometry();

	uint particleIndex = culledIndirectionBuffer2[culledIndirectionBuffer[instanceID]];
	uint vertexID = particleIndex * 4 + vid;

	float4 pos_nor_wind = bindless_buffers_float4[geometry.vb_pos_nor_wind][vertexID];
	float3 position = pos_nor_wind.xyz;
	float3 normal = normalize(unpack_unitvector(asuint(pos_nor_wind.w)));
	float4 uvsets = bindless_buffers_float4[geometry.vb_uvs][vertexID];
	float4 color = bindless_buffers_float4[geometry.vb_col][vertexID];


	// load particle data:
	Particle particle = particleBuffer[particleIndex];

	// calculate render properties from life:
	float lifeLerp = 1 - particle.life / particle.maxLife;
	float size = lerp(particle.sizeBeginEnd.x, particle.sizeBeginEnd.y, lifeLerp);

	// Sprite sheet UV transform:
	const float spriteframe = xEmitterFrameRate == 0 ? 
		lerp(xEmitterFrameStart, xEmitterFrameCount, lifeLerp) : 
		((xEmitterFrameStart + particle.life * xEmitterFrameRate) % xEmitterFrameCount);
	const float frameBlend = frac(spriteframe);

	VertextoPixel Out;
	Out.P = position;
	Out.pos = mul(GetCamera().view_projection, float4(position, 1));
	Out.tex = uvsets;
	Out.size = size;
	Out.color = pack_rgba(color);
	Out.unrotated_uv = BILLBOARD[vertexID % 4].xy * float2(1, -1) * 0.5f + 0.5f;
	Out.frameBlend = frameBlend;
	return Out;
}
