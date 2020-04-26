import QtQuick 2.9

ShaderEffect {
    id: effect

    smooth: false
    blending: false
    supportsAtlasTextures: false

    property QtObject context

    /*
     * Shader Inputs
     * uniform vec3      iResolution;           // viewport resolution (in pixels)
     * uniform float     iTime;                 // shader playback time (in seconds)
     * uniform float     iTimeDelta;            // render time (in seconds)
     * uniform int       iFrame;                // shader playback frame
     * uniform float     iChannelTime[4];       // channel playback time (in seconds)
     * uniform vec3      iChannelResolution[4]; // channel resolution (in pixels)
     * uniform vec4      iMouse;                // mouse pixel coords. xy: current (if MLB down), zw: click
     * uniform samplerXX iChannel0..3;          // input channel. XX = 2D/Cube
     * uniform vec4      iDate;                 // (year, month, day, time in seconds)
     * uniform float     iSampleRate;           // sound sample rate (i.e., 44100)
     */

    property var iChannel0
    property var iChannel1
    property var iChannel2
    property var iChannel3

    readonly property vector3d iResolution: Qt.vector3d(width, height, 1.0)
    readonly property real iTime: context.iTime
    readonly property real iTimeDelta: context.iTimeDelta
    readonly property int iFrame: context.iFrame
    readonly property vector4d iMouse: context.iMouse
    readonly property vector4d iDate: context.iDate
    readonly property var iChannelTime: [0, 0, 0, 0]
    readonly property var iChannelResolution: [Qt.vector3d(width, height, 0.0)]
    readonly property real iSampleRate: 44100

    onStatusChanged: {
        switch (status) {
            case ShaderEffect.Uncompiled:
                console.log(objectName, "Loading shader");
                break;
            case ShaderEffect.Compiled:
                console.log(objectName, "Loaded shader");
                break;
            case ShaderEffect.Error:
                console.log(objectName, "Failed to load shader");
                break;
        }
    }

    onLogChanged: {
        if (log != "")
            console.log(objectName, log);
    }
}
