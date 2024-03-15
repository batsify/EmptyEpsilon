#pragma once

#include "io/dataBuffer.h"
#include "multiplayer.h"
#include "script/callback.h"


class RadarTrace
{
public:
    static constexpr uint32_t Rotate = 1 << 0;
    static constexpr uint32_t ColorByFaction = 1 << 1;
    static constexpr uint32_t ArrowIfNotScanned = 1 << 2;
    static constexpr uint32_t BlendAdd = 1 << 3;
    static constexpr uint32_t LongRange = 1 << 4;

    string icon;
    float min_size = 16.0;   //Size in screen "pixels"
    float max_size = 256.0; //Size in screen "pixels"
    float radius = 0.0;     // Size in world "units"
    glm::u8vec4 color{255,255,255,255};

    uint32_t flags = Rotate | LongRange;

    bool operator!=(const RadarTrace& o)
    {
        return icon != o.icon || min_size != o.min_size || max_size != o.max_size || radius != o.radius || color != o.color || flags != o.flags;
    }
};
static inline sp::io::DataBuffer& operator << (sp::io::DataBuffer& packet, const RadarTrace& rt) { return packet << rt.icon << rt.min_size << rt.max_size << rt.radius << rt.color << rt.flags; }
static inline sp::io::DataBuffer& operator >> (sp::io::DataBuffer& packet, RadarTrace& rt) { return packet >> rt.icon >> rt.min_size >> rt.max_size >> rt.radius >> rt.color >> rt.flags; }


// Radar signature data, used by rawScannerDataOverlay.
class RawRadarSignatureInfo
{
public:
    float gravity;
    float electrical;
    float biological;

    RawRadarSignatureInfo()
    : gravity(0), electrical(0), biological(0) {}

    RawRadarSignatureInfo(float gravity, float electrical, float biological)
    : gravity(gravity), electrical(electrical), biological(biological) {}

    RawRadarSignatureInfo& operator+=(const RawRadarSignatureInfo& o)
    {
        gravity += o.gravity;
        electrical += o.electrical;
        biological += o.biological;
        return *this;
    }

    bool operator!=(const RawRadarSignatureInfo& o)
    {
        return gravity != o.gravity || electrical != o.electrical || biological != o.biological;
    }

    RawRadarSignatureInfo operator*(const float f) const
    {
        return RawRadarSignatureInfo(gravity * f, electrical * f, biological * f);
    }
};
static inline sp::io::DataBuffer& operator << (sp::io::DataBuffer& packet, const RawRadarSignatureInfo& rrs) { return packet << rrs.gravity << rrs.electrical << rrs.biological; }
static inline sp::io::DataBuffer& operator >> (sp::io::DataBuffer& packet, RawRadarSignatureInfo& rrs) { packet >> rrs.gravity >> rrs.electrical >> rrs.biological; return packet; }

// Dynamic radar signature is added to entities that
//  generate additional radar signature info by live systems (impulse engine, etc...)
class DynamicRadarSignatureInfo
{
public:
    float gravity = 0.0f;
    float electrical = 0.0f;
    float biological = 0.0f;
};

//TODO: This is currently a bit of a catch all components, and should be split up.
class LongRangeRadar
{
public:
    float short_range = 5000.0f;
    float long_range = 30000.0f;

    std::vector<glm::vec2> waypoints;
    sp::ecs::Entity radar_view_linked_entity;

    sp::script::Callback on_probe_link;
    sp::script::Callback on_probe_unlink;
};

class ShareShortRangeRadar
{
};

class AllowRadarLink
{
public:
    sp::ecs::Entity owner;
};
