import QtQuick 2.9

ShaderEffectSource {
    id: self
    property alias source: img.source
    hideSource: true
    sourceItem: Image {
        id: img
        onStatusChanged: {
            switch (status) {
                case Image.Loading:
                    console.log(self.objectName, "Loading texture from " + source);
                    break;
                case Image.Ready:
                    console.log(self.objectName, "Loaded texture");
                    break;
                case Image.Error:
                    console.log(self.objectName, "Failed to load texture");
                    break;
            }
        }
    }
}
