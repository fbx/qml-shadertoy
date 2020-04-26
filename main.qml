import QtQuick 2.9
import QtQuick.Window 2.2
import "shadertoy.js" as Toy
import fbx.async 1.0 as Async
import fbx.web 1.0 as Web

Window {
    id: self
    visible: true
    width: 800
    height: 450
    color: "black"
    title: qsTr("ShaderToy")

    /*
     * WslfD7 (Weird Machine That Does Nothing): broken colors
     * 3ddGzn (Then and Before): multi buffers
     * 3tGSR3 (Day 74): one buffer, no self reference
     * MdX3Rr (Elevated): one buffer, no self reference
     * XsX3RB (Volcanic): one buffer, no self reference
     * 4ttSWf (Rainforest): one buffer with self reference
     */

    property var client: Toy.createClient()
    property var shadersCache: ({})
    property var defaultList: ["4X3yRn", "4XsfDs", "MXccR4", "4ccfRn", "dljBWz", "NslGRN", "wly3DW", "MfVfz3", "MtGSRm", "Dds3WB", "lsX3W4", "llj3Rz", "ltffzl", "3tGSR3", "wtcSzN", "ttKGDt", "sdlfRj", "Ns3XWf", "7lKSWW", "4ttSWf","4dcGW2","tsXBzS","fdffz2","fslcDS","3ddGzn","llK3Dy","ls3BDH","XsBXWt","XdlGzr","lds3zr", "3lsSzf", "XtlSD7"]
    property var shadersList: []
    property string shaderId
    property alias shaderView: shaderViewLoader.item
    property bool showDebugInfo: false

    onFrameSwapped: {
        if (shaderView)
            shaderView.iFrame++;
    }

    onShaderIdChanged: {
        shaderViewLoader.active = false;
        shaderDebugText.text = "";
        shaderTitleText.text = "";

        if (!shaderId)
            return;

        var q;
        if (shadersCache[shaderId]) {
            q = Async.Deferred.resolved(shadersCache[shaderId]);
        } else {
            q = self.client.shaders(shaderId).read({
                key: Toy.apiKey,
            }).then(function (ret) {
                if (ret.Error)
                    return Async.Deferred.rejected(ret.Error);
                shadersCache[shaderId] = ret.Shader;
                return ret.Shader;
            });
        }

        q.then(function (shader) {
            shaderTitleText.text = "<b>" + shader.info.name + "</b> by <b>" + shader.info.username + "</b>";

            var debugText = "";
            for (var r = 0; r < shader.renderpass.length; r++) {
                var rpass = shader.renderpass[r];
                debugText += "<b>Render pass " + r + "</b>: " + rpass.name + " (" + rpass.type + ")<ul>";
                for (var i = 0; i < rpass.inputs.length; i++) {
                    var input = rpass.inputs[i];
                    debugText += "<li>Input " + input.channel + "</b>: " + input.ctype + ", id " + input.id + "</li>";
                }
                for (var i = 0; i < rpass.outputs.length; i++) {
                    var output = rpass.outputs[i];
                    debugText += "<li>Output " + output.channel + "</b>: id " + output.id + "</li>";
                }
                debugText += "</ul>";
            }

            shaderDebugText.text = debugText;
            shaderViewLoader.active = true;
            shaderView.shaderInfo = shader;

        }).fail(function (err) {
            shaderTitleText.text = err.value;
        });
    }

    Loader {
        id: shaderViewLoader
        anchors.fill: parent
        sourceComponent: shaderViewComponent
    }

    Component {
        id: shaderViewComponent
        ShaderToy {
            anchors.fill: parent
        }
    }

    ListView {
        id: listview
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.margins: 50
        width: 200
        focus: true
        model: self.shadersList

        header: Text {
            text: "Shader list"
            color: "#3060ed"
            font.pixelSize: 22
            font.bold: true
            font.underline: true
        }

        delegate: Text {
            text: modelData
            color: ListView.isCurrentItem ? "white" : "#666666"
            font.pixelSize: 20
        }

        onCurrentIndexChanged: {
            listview.opacity = 1;
            self.shaderId = null;
            stableTimer.restart();
        }

        Timer {
            id: stableTimer
            interval: 1000
            running: false
            onTriggered: {
                listview.opacity = 0;
                self.shaderId = self.shadersList[listview.currentIndex];
            }
        }

        Keys.onPressed: {
            switch (event.key) {
            case Qt.Key_Help:
                showDebugInfo = !showDebugInfo;
                event.accepted = true;
                break;
            }
        }

        Behavior on opacity { PropertyAnimation {} }
    }

    Text {
        id: shaderTitleText
        opacity: 0.6
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: listview.right
        anchors.margins: 40
        textFormat: Text.AutoText
        color: "white"
        font.pixelSize: 40
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
        style: Text.Sunken
        styleColor: "black"
    }

    Rectangle {
        anchors.fill: shaderDebugText
        anchors.margins: -20
        radius: 10
        border.color: "#80666666"
        border.width: 3
        color: "#c0000000"
        visible: shaderDebugText.visible
    }

    Text {
        id: shaderDebugText
        visible: showDebugInfo && text != ""
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 40
        textFormat: Text.RichText
        color: "white"
        font.pixelSize: 20
    }

    Component.onCompleted: {
        if (shadersList && shadersList.length > 0)
            return;
    }

    function handleUrl(action, url, mimeType) {
        var u = new Web.Http.URL(url);
        var query = u.query.get("query");
        var sort = u.query.get("sort");
        if (query === undefined && sort === undefined) {
            self.shadersList = self.defaultList;
        } else {
            self.client.shaders.query(query).read({
                sort: sort ?? "hot",
                key: Toy.apiKey,
                from: 0, num: 100,
            }).then(function (ret) {
                console.log("got " + ret.Shaders + " shaders");
                self.shadersList = ret.Results;
            });
        }
    }
}
