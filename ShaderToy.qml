import QtQuick 2.9
import QtMultimedia 5.9

MouseArea {
    id: self

    property int shaderWidth: 400
    property int shaderHeight: 225
    property var shaderInfo

    property alias iTime: shaderContext.iTime
    property alias iFrame: shaderContext.iFrame

    QtObject {
        id: shaderContext
        property real iTime
        property real iTimeLast
        property real iTimeDelta
        property int iFrame
        property vector4d iMouse
        property vector4d iDate

        onITimeChanged: {
            iTimeDelta = iTime - iTimeLast;
            iTimeLast = iTime;
        }

        function reset()
        {
            iTime = 0;
            iTimeLast = 0;
            iTimeDelta = 0;
            iFrame = 0;
            iMouse = Qt.vector4d(0, 0, 0, 0);
        }
    }

    layer.enabled: shaderWidth != width || shaderHeight != height
    layer.textureSize: Qt.size(shaderWidth, shaderHeight)
    layer.sourceRect: Qt.rect(0, 0, shaderWidth, shaderHeight)
    layer.smooth: true

    onPositionChanged: {
        var x = Math.round(mouseX * (shaderWidth / width));
        var y = Math.round(shaderHeight - mouseY * (shaderHeight / height));
        shaderContext.iMouse = Qt.vector4d(x, y, shaderContext.iMouse.z, shaderContext.iMouse.w);
    }

    onPressed: {
        var x = Math.round(mouseX * (shaderWidth / width));
        var y = Math.round(shaderHeight - mouseY * (shaderHeight / height));
        shaderContext.iMouse = Qt.vector4d(x, y, x, y);
    }

    onReleased: {
        shaderContext.iMouse = Qt.vector4d(shaderContext.iMouse.x,
                                           shaderContext.iMouse.y,
                                           -shaderContext.iMouse.z,
                                           -shaderContext.iMouse.w);
    }

    onDoubleClicked: shaderTime.restart()

    onShaderInfoChanged: {
        if (!shaderInfo)
            return;

        processShaderInfo(shaderInfo, self);
    }

    NumberAnimation on iTime {
        id: shaderTime
        from: 0
        to: 1000
        duration: 1000000
        loops: Animation.Infinite
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date();
            shaderContext.iDate = Qt.vector4d(date.getFullYear(),
                                              date.getMonth(),
                                              date.getDay(),
                                              date.getHours() * 3600 +
                                              date.getMinutes() * 60 +
                                              date.getSeconds());
        }
    }

    function findOutputWithId(info, id)
    {
        for (var r = 0; r < info.renderpass.length; r++) {
            var rpass = info.renderpass[r];
            for (var i = 0; i < rpass.outputs.length; i++) {
                var output = rpass.outputs[i];
                if (output.id == id)
                    return rpass.object;
            }
        }
        return null;
    }

    function processShaderInfo(info, context)
    {
        var commonCode = "";

        print("process", JSON.stringify(info, (k, v) => { return k === "code" ? "..." : v }, ' '));

        for (var i = 0; i < info.renderpass.length; i++) {
            if (info.renderpass[i].type === "common")
                commonCode += info.renderpass[i].code;
        }

        for (var r = 0; r < info.renderpass.length; r++) {
            var rpass = info.renderpass[r];
            if (rpass.type === "common")
                continue;

            if (rpass.type === "sound")
                continue;

            var inputs = [null, null, null, null];
            var inputsCode = "";

            for (var i = 0; i < rpass.inputs.length; i++) {
                var input = rpass.inputs[i];
                inputs[input.channel] = input;
            }

            for (var i = 0; i < rpass.outputs.length; i++) {
                var output = rpass.outputs[i];
            }

            for (var i = 0; i < inputs.length; i++) {
                var input = inputs[i];

                if (input === null)
                    inputsCode += "uniform sampler2D iChannel" + i + ";\n";
                else if (input.ctype === "cubemap")
                    inputsCode += "uniform samplerCube iChannel" + i + ";\n";
                else if (input.ctype === "volume")
                    inputsCode += "uniform sampler3D iChannel" + i + ";\n";
                else
                    inputsCode += "uniform sampler2D iChannel" + i + ";\n";

                if (input === null)
                    continue;

                var srcUrl = "https://www.shadertoy.com" + input.src;
                if (input.ctype == "music") {
                    input.player = musicComponent.createObject(context, {
                        objectName: "ShaderInput:" + r + ":" + input.channel + ":" + input.ctype,
                        source: srcUrl,
                    });
                    continue;
                }

                if (input.ctype !== "texture" && input.ctype !== "buffer") {
                    console.warn("shader input type '" + input.ctype + "' is not supported");
                    continue;
                }

                var mipmap = input.sampler.filter === "mipmap";
                var wrapMode = ShaderEffectSource.ClampToEdge;
                var textureMirroring = ShaderEffectSource.MirrorVertically;

                if (input.sampler.wrap === "repeat")
                        wrapMode = ShaderEffectSource.Repeat;

                if (input.sampler.vflip === "true")
                    textureMirroring = ShaderEffectSource.NoMirroring;

                if (input.ctype === "texture") {
                    input.object = textureComponent.createObject(context, {
                        objectName: "ShaderInput:" + r + ":" + input.channel + ":" + input.ctype,
                        source: srcUrl,
                        mipmap: mipmap,
                        wrapMode: wrapMode,
                        textureMirroring: textureMirroring,
                    });
                } else if (input.ctype === "buffer") {
                    var recursive = false;
                    for (var o = 0; o < rpass.outputs.length; o++) {
                        var output = rpass.outputs[o];
                        if (output.id === input.id) {
                            recursive = true;
                            break;
                        }
                    }
                    input.object = bufferComponent.createObject(context, {
                        objectName: "ShaderInput:" + r + ":" + input.channel + ":" + input.ctype,
                        mipmap: mipmap,
                        recursive: recursive,
                        wrapMode: wrapMode,
                        textureMirroring: textureMirroring,
                    });
                }

                console.log("created input", input.ctype, input.id, "=>", input.object.objectName);
            }

            var versionString = "#version 300 es\n" +
                                "#ifdef GL_ES\n" +
                                "precision highp float;\n" +
                                "precision highp int;\n" +
                                "precision mediump sampler3D;\n" +
                                "#endif\n";

            var vertexShader = versionString +
                "uniform mat4 qt_Matrix;\n" +
                "in vec4 qt_Vertex;\n" +
                "in vec2 qt_MultiTexCoord0;\n" +
                "out vec2 qt_TexCoord0;\n" +
                "void main() {\n" +
                "    qt_TexCoord0 = qt_Vertex.xy;\n" +
                "    gl_Position = qt_Matrix * qt_Vertex;\n" +
                "}\n";

            var fragmentShader = versionString +
                "#define HW_PERFORMANCE 0\n" +
                "in vec2 qt_TexCoord0;\n" +
                "out vec4 fragColor;\n" +
                "uniform float qt_Opacity;\n" +
                "uniform vec3 iResolution;\n" +
                "uniform float iTime;\n" +
                "uniform float iTimeDelta;\n" +
                "uniform int iFrame;\n" +
                "uniform float iChannelTime[4];\n" +
                "uniform vec3 iChannelResolution[4];\n" +
                "uniform vec4 iMouse;\n" +
                "uniform vec4 iDate;\n" +
                "uniform float iSampleRate;\n" +
                inputsCode + "\n" +
                commonCode + "\n" +
                rpass.code + "\n" +
                "void main(void)\n" +
                "{\n" +
                "    mainImage(fragColor, vec2(qt_TexCoord0.x, iResolution.y - qt_TexCoord0.y));\n" +
                "}\n";

            shaderContext.reset();
            shaderTime.restart();

            var shader = shaderComponent.createObject(context, {
                objectName: "ShaderRenderPass:" + r + ":" + rpass.name,
                context: shaderContext,
                width: shaderWidth,
                height: shaderHeight,
                vertexShader: vertexShader,
                fragmentShader: fragmentShader,
                iChannel0: inputs[0] ? inputs[0].object : null,
                iChannel1: inputs[1] ? inputs[1].object : null,
                iChannel2: inputs[2] ? inputs[2].object : null,
                iChannel3: inputs[3] ? inputs[3].object : null,
            });

            rpass.object = shader;
        }

        for (var r = 0; r < info.renderpass.length; r++) {
            var rpass = info.renderpass[r];

            for (var i = 0; i < rpass.inputs.length; i++) {
                var input = rpass.inputs[i];
                if (input.ctype === "buffer") {
                    var obj = findOutputWithId(info, input.id);
                    if (!obj) {
                        console.warn("could not find output with id", input.id);
                        continue;
                    }
                    console.log("bind output", input.id, obj.objectName, "to input", input.object.objectName);
                    input.object.sourceItem = obj;
                }
            }
        }
    }

    property Component textureComponent: ShaderInputImage {}
    property Component bufferComponent: ShaderInputBuffer {}
    property Component shaderComponent: ShaderRenderPass {}
    property Component musicComponent: Audio { autoPlay: true }
}
