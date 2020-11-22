import QtQuick 2.0
import QtQuick.Controls 1.2
import QtQuick.Layouts 1.1
import Machinekit.Application.Controls 1.0

ColumnLayout {
    id: root

    RowLayout {
        Layout.fillWidth: true

        Label {
            text: qsTr("Axis")
        }

        Item {
            Layout.fillWidth: true
        }

        AxisRadioGroup {
            id: axisRadioGroup
            Layout.fillWidth: false
        }
    }

    RowLayout {
        Layout.fillWidth: true

        JogButton {
            id: decrementButton
            Layout.fillWidth: false
            direction: -1
            distance: jogCombo.distance
            joint: axisRadioGroup.joint
        }

        JogButton {
            id: incrementButton
            Layout.fillWidth: false
            direction: 1
            distance: jogCombo.distance
            joint: axisRadioGroup.joint
        }

        JogDistanceComboBox {
            id: jogCombo
            Layout.fillWidth: true
            joint: axisRadioGroup.joint
        }

        KeyboardJogControl {
            id: keyboardJogControl
            enabled: jogCombo.distance !== 0.0
            onSelectAxis: axisRadioGroup.joint = joint
            onIncrement: incrementButton._toggle(enabled)
            onDecrement: decrementButton._toggle(enabled)
            onSelectIncrement: {
                if (jogCombo.currentIndex == 0) {
                    jogCombo.currentIndex = index;
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        Button {
            id: homeAllAxesButton
            Layout.fillWidth: false
            action: HomeAxisAction { id: homeAxisAction; joint: -1 }
            visible: homeAxisAction.homeAllAxesHelper.homingOrderDefined
        }

        Button {
            id: homeAxisButton
            Layout.fillWidth: false
            action: HomeAxisAction { joint: axisRadioGroup.joint }
            visible: !homeAllAxesButton.visible
        }

        Button {
            Layout.fillWidth: false
            action: TouchOffAction { touchOffDialog: touchOffDialog }
        }

        Item {
            Layout.fillWidth: true
        }

        TouchOffDialog {
            id: touchOffDialog
            joint: axisRadioGroup.joint
            height: window.height * 0.2
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false

        Label {
            text: qsTr("Jog Velocity")
        }
        Item {
            Layout.fillWidth: true
        }

        Label {
            text: jogVelocitySlider.displayValue.toFixed(1) + " " + jogVelocitySlider.units
        }
    }

    JogVelocitySlider {
        id: jogVelocitySlider
        Layout.fillWidth: true
        joint: axisRadioGroup.joint
        proportional: true
    }
}
