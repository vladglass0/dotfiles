import QtQuick

// Text with angelOS's pixel-font defaults. kind: tiny | body | title
Text {
    property string kind: "body"
    property bool dim: false
    color: dim ? Theme.textDim : Theme.text
    font.family: kind === "body" ? Theme.fontBody : Theme.fontTitle
    font.pixelSize: kind === "tiny" ? Theme.sizeTiny : kind === "title" ? Theme.sizeTitle : Theme.sizeBody
    font.hintingPreference: Font.PreferFullHinting
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    // track and window names are not HTML
    textFormat: Text.PlainText
}
