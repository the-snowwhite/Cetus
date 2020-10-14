import QtQuick 2.0
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import QtQuick.Window 2.0
import Machinekit.Application 1.0
import Machinekit.Application.Controls 1.0
import Qt.labs.settings 1.0
import QtQuick.Controls.Styles 1.4

Item {
    //    title: qsTr("Probe")
    id: root
    property var posnr: 0
    property var xpos: 0
    property var ypos: 0
    property var zpos: 0

    Settings {
        property alias xmin: xminspinbox.value
        property alias xmax: xmaxspinbox.value
        property alias ymin: yminspinbox.value
        property alias ymax: ymaxspinbox.value
        property alias z: zspinbox.value
        property alias zfeed: zfeedbox.value
        property alias probeto: prbtobox.value
        property alias numprobes: numprobesbox.value
        property alias prboffset: prboffsetbox.value
    }

    Timer {
        id: timer
        function setTimeout(cb, delayTime) {
            timer.interval = delayTime;
            timer.repeat = false;
            timer.triggered.connect(cb);
            timer.triggered.connect(function release () {
                timer.triggered.disconnect(cb); // This is important
                timer.triggered.disconnect(release); // This is important as well
            });
            timer.start();
        }
    }

    QtObject {
        id: g
        function gotoposition() {
            switch(root.posnr) {
                case 0:
                    root.xpos = xminspinbox.value.toFixed(1)
                    root.ypos = yminspinbox.value.toFixed(1)
                    break
                case 1:
                    root.xpos = xmaxspinbox.value.toFixed(1)
                    root.ypos = yminspinbox.value.toFixed(1)
                    break
                case 2:
                    root.xpos = xminspinbox.value.toFixed(1)
                    root.ypos = ymaxspinbox.value.toFixed(1)
                    break
                case 3:
                    root.xpos = xmaxspinbox.value.toFixed(1)
                    root.ypos = ymaxspinbox.value.toFixed(1)
                    break
            }
            root.zpos = zspinbox.value.toFixed(1)
            probecommands.append("Going to -> " + positems.get(root.posnr).text + "x: %1 y: %2 z: %3 ".arg(xpos).arg(ypos).arg(root.zpos))
            gcodecmdAction.mdiCommand = "G94"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "G21"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "G90"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "G53 G0 Z%1".arg(root.zpos)
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "G53 G0 X%1 Y%2".arg(xpos).arg(ypos)
            gcodecmdAction.trigger()
            //            gcodecmdAction.mdiCommand = "G53 G0 Z%1".arg(root.zpos)
            //            gcodecmdAction.trigger()
        }

        function probeavg() {
            gcodecmdAction.mdiCommand = "G94;";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "G21;";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "G90;";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "M65 P0 (disable probe input);";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "(PROBEOPEN ref_probe-results_" + positems.get(root.posnr).text + ".txt);";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "T100;"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "M6      (Tool change);"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "#2 = 0;";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "#3 = 99;";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "#4 = -99;";
            gcodecmdAction.trigger();
            for(var i=0;i<numprobesbox.value.toFixed(1);i++) {
                gcodecmdAction.mdiCommand = "G49;";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "M64 P0 (enable probe input);";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "G38.2 Z" + prbtobox.value.toFixed(1) + " F"+ zfeedbox.value.toFixed(1)   + " (measure);";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "M65 P0 (disable probe input);";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "G91 G0Z5 (off the switch);";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "#2=[#5063 + #2] (sum reference tool length);";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "G90 (done);";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "o102 if [#5063 LT #3] (if parameter #5063 is less than #3 put length in #3)";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "#3=#5063";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "o102 elseif [#5063 GT #4] (if parameter #5063 is greater than #4 put length in #4)";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "#4=#5063";
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "o102 endif";
                gcodecmdAction.trigger();
                gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "G49;"
                gcodecmdAction.trigger();
            }
            gcodecmdAction.mdiCommand = "#5=[#4 - #3] (save reference tool probes max diversion);";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "#1000=[#2/" + numprobesbox.value.toFixed(1) + "] (save avarage reference tool length);";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "(debug,avarage: " + positems.get(root.posnr).text + " #1000\n min: #3\n max: #4\n delta: #5);";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "(PROBECLOSE);";
            gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "G91 G0Z5;";
            gcodecmdAction.trigger();
            probecommands.append("AvgProbe finished \n ");
        }

        function dlymsg(x) {
            if(x==1) {
                gcodecmdAction.mdiCommand = "M65 P0 (disable probe input);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "(PROBEOPEN ref_probe-results_" + positems.get(root.posnr).text + ".txt);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "T100;"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "M6      (Tool change);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "#2 = 0;"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "#3 = 99;"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "#4 = -99;"; gcodecmdAction.trigger();
                for(var i=0;i<numprobesbox.value.toFixed(1);i++) {
                    gcodecmdAction.mdiCommand = "G49;"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "M64 P0 (enable probe input);"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "G38.2 Z" + prbtobox.value.toFixed(1) + " F"+ zfeedbox.value.toFixed(1)   + " (measure);"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "M65 P0 (disable probe input);"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "G91 G0Z5 (off the switch);"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "#2=[#5063 + #2] (sum reference tool length);"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "G90 (done);"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "o102 if [#5063 LT #3] (if parameter #5063 is less than #3 put length in #3)"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "#3=#5063"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "o102 endif"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "o102 if [#5063 GT #4] (if parameter #5063 is greater than #4 put length in #4)"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "#4=#5063"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "o102 endif"; gcodecmdAction.trigger();
                    gcodecmdAction.mdiCommand = "G49;"; gcodecmdAction.trigger();
                }
                gcodecmdAction.mdiCommand = "#5=[#4 - #3] (save reference tool probes max diversion);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "#1000=[[#2/" + numprobesbox.value.toFixed(1) + "]+" + prboffsetbox.value.toFixed(3) + "] (save avarage reference tool length);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "(debug,Z zero: " + positems.get(root.posnr).text + " #1000\n min: #3\n max: #4\n delta: #5);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "(PROBECLOSE);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "G91 G0Z5;"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "G10 L2 P1 z#1000 (set G54 Z offset to avg probe value plus offset);"; gcodecmdAction.trigger();
                gcodecmdAction.mdiCommand = "G90"; gcodecmdAction.trigger();
                probecommands.append("RefProbe finished \n ");
            }
        }

        function proberef() {
            g.dlymsg(0);
            gcodecmdAction.mdiCommand = "(debug,R Prb Clicked)"; gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "G94;"; gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "G21;"; gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "G90;"; gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "G10 L2 P1 z0 (set G54 Z offset to 0);"; gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "T0 (set tool 0) ;"; gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "M6 (Tool change and goto tool probe ref point) ;"; gcodecmdAction.trigger();
            gcodecmdAction.mdiCommand = "(debug,Will move to G28.1 while waiting 8 seconds before probing)"; gcodecmdAction.trigger();
            timer.setTimeout(function(){ g.dlymsg(1); }, 8000);
        }

        function probeinplace() {
            gcodecmdAction.mdiCommand = "G94"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "G21"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "G90"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "M65 P0 (disable probe input)"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "(PROBEOPEN ref_probe-results_" + positems.get(root.posnr).text + ".txt)"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "T100"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "M6      (Tool change)"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "#2 = 0"
            gcodecmdAction.trigger()
            for(var i=0;i<numprobesbox.value.toFixed(1);i++) {
                gcodecmdAction.mdiCommand = "G49"
                gcodecmdAction.trigger()
                gcodecmdAction.mdiCommand = "M64 P0 (enable probe input)"
                gcodecmdAction.trigger()
                gcodecmdAction.mdiCommand = "G38.2 Z" + prbtobox.value.toFixed(1) + " F"+ zfeedbox.value.toFixed(1)   + " (measure)"
                gcodecmdAction.trigger()
                gcodecmdAction.mdiCommand = "M65 P0 (disable probe input)"
                gcodecmdAction.trigger()
                gcodecmdAction.mdiCommand = "G91 G0Z5 (off the switch)"
                gcodecmdAction.trigger()
                gcodecmdAction.mdiCommand = "#2=[#5063 + #2] (sum reference tool length)"
                gcodecmdAction.trigger()
                gcodecmdAction.mdiCommand = "G90 (done)"
                gcodecmdAction.trigger()
                probecommands.append("\r Probe nr  %1 of %2 ".arg(i).arg(numprobesbox.value.toFixed(1)))
            }
            gcodecmdAction.mdiCommand = "#1000=[#2/" + numprobesbox.value.toFixed(1) + "] (save avarage reference tool length)"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "(debug,avarage " + positems.get(root.posnr).text + " length is #1000)"
            gcodecmdAction.trigger()
            gcodecmdAction.mdiCommand = "(PROBECLOSE)"
            gcodecmdAction.trigger()
            probecommands.append("AvgProbe finished \n ")
        }
    }

    ColumnLayout {
        id: columnspace
        width: Screen.width - Screen.pixelDensity * 6
        spacing: Screen.pixelDensity
        Layout.fillHeight: true

        DigitalReadOut {
            id: dro
            textColor: "black"
        }

        MdiCommandAction {
            id: gcodecmdAction
            enableHistory: false
        }

        GridLayout {
            columns: 6
            rows: 5
            Layout.fillWidth: true
            Layout.fillHeight: true
            //        anchors.fill: parent


            Label {
                text: qsTr("X min:")
                color: "blue"
            }

            Label {
                text: qsTr("X max:")
                color: "blue"
            }

            Label {
                text: qsTr("Y min:")
                color: "blue"
            }

            Label {
                text: qsTr("Y max:")
                color: "blue"
            }

            Label {
                text: qsTr("Z:")
                color: "blue"
            }

            Component {
                id:comboBoxStyle
                ComboBoxStyle {
                    background: Rectangle {
                        id: rect
                        border.color: "blue"
                        border.width: 2
                        color: "white"
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: 2
                            font.pointSize: 15
                            font.family: "sans serif"
                            color: control.hovered?"#FF6BC1E5":"#FF404040"
                            text:"˅"
                        }
                    }
                }
            }

            ComboBox {
                id: cnrcombo
                currentIndex: 0
                implicitWidth: positionButton.width
                implicitHeight: positionButton.height
                style: comboBoxStyle
                model: ListModel {
                    id: positems
                    ListElement { text: "L Front"; color: "green"; inx: 0}
                    ListElement { text: "R Front"; color: "Blue"; inx: 1}
                    ListElement { text: "L Back"; color: "Green"; inx: 2}
                    ListElement { text: "R Back"; color: "Red"; inx: 3}
                }
                onCurrentIndexChanged: {
                    positionButton.text = "---> " + positems.get(currentIndex).text
                    root.posnr = currentIndex
                }
            }

            Component {
                id:spinBoxStyle_blue
                SpinBoxStyle {
                    background: Rectangle {
                        //                            implicitWidth: zfeedbox.width //146
                        implicitWidth: 172
                        implicitHeight: 26
                        border.color: "blue"
                        border.width: 2
                        radius: 2
                    }
                }
            }

            Component {
                id:spinBoxStyle_green
                SpinBoxStyle {
                    background: Rectangle {
                        //                            implicitWidth: zfeedbox.width //146
                        implicitWidth: 172
                        implicitHeight: 26
                        border.color: "green"
                        border.width: 3
                        radius: 2
                    }
                }
            }

            SpinBox {
                id: xminspinbox
                suffix: "mm"
                style: spinBoxStyle_blue
                minimumValue: -999.9
                maximumValue: 999.9
                decimals: 2
                stepSize: 10.0
            }

            SpinBox {
                id: xmaxspinbox
                style: spinBoxStyle_blue
                suffix: "mm"
                minimumValue: -999.9
                maximumValue: 999.9
                value: 390
                decimals: 2
                stepSize: 10.0
            }

            SpinBox {
                id: yminspinbox
                style: spinBoxStyle_blue
                suffix: "mm"
                minimumValue: -999.9
                maximumValue: 999.9
                decimals: 2
                stepSize: 10.0
            }

            SpinBox {
                id: ymaxspinbox
                style: spinBoxStyle_blue
                suffix: "mm"
                minimumValue: -999.9
                maximumValue: 999.9
                value: 340
                decimals: 2
                stepSize: 10.0
            }

            SpinBox {
                id: zspinbox
                style: spinBoxStyle_blue
                suffix: "mm"
                minimumValue: -999.9
                maximumValue: 999.9
                value: -10
                decimals: 3
                stepSize: 1.0
            }

            Button {
                id: positionButton
                text: "---> L Front"
                style: ButtonStyle {
                    background: Rectangle {
                        border.color: "blue"
                        border.width: 2
                    }
                }
                tooltip: qsTr("Go to Z: and then to \nX/Y min/max corner \nset in above menu")
                onClicked: {
                    g.gotoposition()
                }
            }

            Label {
                text: qsTr("Prb-feed:")
                color: "green"
            }

            Label {
                text: qsTr("Prb-To")
                color: "green"
            }

            Label {
                text: qsTr("Num Probes")
                color: "green"
            }

            Label {
                text: qsTr("Prb offset")
                color: "green"
            }

            Button {
                id: probeinplace
                implicitWidth: zspinbox.width
                style: ButtonStyle {
                    background: Rectangle {
                        border.color: "red"
                        border.width: 2
                    }
                }
                text: qsTr("Prb in place")
                tooltip: qsTr("Probe on current position \nand print avarage")
                onClicked: {
                    g.probeinplace()
                }
            }

            Button {
                id: probecorners
                text: qsTr("Prb Cnr")
                Layout.alignment: Qt.AlignRight
                style: ButtonStyle {
                    background: Rectangle {
                        border.color: "blue"
                        border.width: 2
                    }
                }
                onClicked: {
                    for(var j=0;j<=3;j++) {
                        cnrcombo.currentIndex = j
                        g.gotoposition()
                        g.probeavg()
                    }
                    cnrcombo.currentIndex = 0
                    g.gotoposition()
                    gcodecmdAction.mdiCommand = "G53 G0 Z0"
                    gcodecmdAction.trigger()
                }
            }

            SpinBox {
                id: zfeedbox
                style: spinBoxStyle_green
                suffix: "mm/m"
                minimumValue: 1.0
                maximumValue: 600.9
                value: 60
                decimals: 2
                stepSize: 1.0
            }

            SpinBox {
                id: prbtobox
                suffix: "mm"
                style: spinBoxStyle_green
                minimumValue: -40.9
                maximumValue: 99.9
                value: 3
                decimals: 2
                stepSize: 0.5
            }

            SpinBox {
                id: numprobesbox
                suffix: ""
                style: spinBoxStyle_green
                minimumValue: 1.0
                maximumValue: 100
                value: 10
                decimals: 0
                stepSize: 1
            }

            SpinBox {
                id: prboffsetbox
                suffix: "mm"
                style: spinBoxStyle_green
                minimumValue: -20.000
                maximumValue: 20.000
                value: 0.000
                decimals: 3
                stepSize: 0.010
            }

            Button {
                id: refprobe

                text: qsTr("TCpos Prb")
                implicitWidth: zspinbox.width
                style: ButtonStyle {
                    background: Rectangle {
                        border.color: "green"
                        border.width: 3
                    }
                }
                tooltip: qsTr("Go to TOOL_CHANGE_POSITION set in .ini file \nthen probe and save avarage in G53")
                onClicked: {
                    g.proberef();
                }
            }

            Label {
                text: qsTr("         ")
            }

            Button {
                id: homeZAxisAction
                text: qsTr("Home Z")
                Layout.fillWidth: false
                action: HomeAxisAction { axis: 2 }
            }

            Button {
                id: setProbeRef
                text: qsTr("Set G28.1")
                style: ButtonStyle {
                    background: Rectangle {
                        border.color: "black"
                        border.width: 2
                    }
                }
                tooltip: qsTr("Set G28.1 to current position")
                onClicked: {
                    gcodecmdAction.mdiCommand = "G28.1"
                    gcodecmdAction.trigger()
                }
            }

            Button {
                id: goToProbeRef
                text: qsTr("Go2 G28.1")
                style: ButtonStyle {
                    background: Rectangle {
                        border.color: "black"
                        border.width: 2
                    }
                }
                tooltip: qsTr("Go to G28.1")
                onClicked: {
                    gcodecmdAction.mdiCommand = "G28 (goto probe ref point)"
                    gcodecmdAction.trigger()
                }
            }
        }

        TextArea {
            Accessible.name: "pcommands"
            id: probecommands
            Layout.fillWidth: true
            Layout.fillHeight: true
            text:
            "(Hello \n"
        }
        //         Item {
        //             Layout.fillHeight: true
        //             Layout.fillWidth: true
        //         }

    }
}
