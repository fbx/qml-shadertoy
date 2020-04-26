import QtQuick 2.9

ShaderEffectSource {
    id: self
    hideSource: true
    //textureSize: "512x512"
    Component.onDestruction: print("DESTROYING", objectName)
}
