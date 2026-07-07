#ifndef COLOR_TOOLS_HLSL
#define COLOR_TOOLS_HLSL

//去色函数
half RGBtoGray(half3 color)
{
    return dot(color, half3(0.299, 0.587, 0.114));
}
#endif